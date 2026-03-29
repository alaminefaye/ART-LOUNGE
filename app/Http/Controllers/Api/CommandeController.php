<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Commande;
use App\Models\Product;
use App\Models\Table;
use App\Models\User;
use App\Enums\MoyenPaiement;
use App\Enums\OrderStatus;
use App\Enums\StatutPaiement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use App\Services\FCMService;

class CommandeController extends Controller
{
    protected $fcmService;

    public function __construct(FCMService $fcmService)
    {
        $this->fcmService = $fcmService;
    }

    /**
     * Liste des commandes
     * GET /api/commandes
     */
    public function index(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = $request->user();
        $query = Commande::with(['table', 'user', 'produits', 'client']);

        // Si l'utilisateur est un client, filtrer par ses commandes uniquement
        if ($user->hasRole('client')) {
            $query->where('user_id', $user->id);
        }

        // Filtre spécial pour "Mes commandes" (current) : toutes les commandes non terminées
        // (sans filtre de date : tant qu'une commande n'est pas payée, elle reste visible)
        if ($request->has('filter') && $request->filter === 'current') {
            $query->where('statut', '!=', OrderStatus::Terminee);
        }
        // Filtre spécial pour "Historique" (history) : commandes terminées uniquement
        elseif ($request->has('filter') && $request->filter === 'history') {
            $query->where('statut', OrderStatus::Terminee);
        }
        // Toutes les commandes (dates / statuts) — tableau de bord personnel / historique complet
        elseif ($request->has('filter') && $request->filter === 'staff_all') {
            // Pas de filtre date ni statut ici (le personnel voit tout le périmètre autorisé)
        }
        // Comportement par défaut (pour compatibilité)
        else {
            // Filtres standards
            if ($request->has('table_id')) {
                $query->ofTable($request->table_id);
            }

            if ($request->has('statut')) {
                $query->ofStatut($request->statut);
            }

            if ($request->has('date')) {
                $query->whereDate('created_at', $request->date);
            } elseif ($request->has('all') && $request->boolean('all')) {
                // Si le paramètre 'all' est présent et vrai, récupérer toutes les commandes
                // (pas de filtre de date)
            } else {
                // Par défaut, commandes du jour (sauf pour les clients qui voient toutes leurs commandes terminées)
                if (!$user->hasRole('client')) {
                    $query->duJour();
                } else {
                    // Pour les clients, par défaut on montre les terminées (historique)
                    $query->where('statut', OrderStatus::Terminee);
                }
            }
        }

        // Recherche : n° commande, table, téléphone ou nom du client fidélité
        if ($request->filled('search')) {
            $term = trim((string) $request->search);
            if ($term !== '') {
                $query->where(function ($q) use ($term) {
                    $digits = preg_replace('/\D/', '', $term);
                    if ($digits !== '' && ctype_digit($digits)) {
                        $q->where('id', (int) $digits);
                    }
                    $q->orWhereHas('table', function ($t) use ($term) {
                        $t->where('numero', 'like', '%' . $term . '%');
                    });
                    $q->orWhereHas('client', function ($c) use ($term) {
                        $like = '%' . $term . '%';
                        $c->where('telephone', 'like', $like)
                            ->orWhere('nom', 'like', $like)
                            ->orWhere('prenom', 'like', $like);
                    });
                });
            }
        }

        $sortDir = strtolower((string) $request->get('sort', 'desc')) === 'asc' ? 'asc' : 'desc';
        $query->orderBy('created_at', $sortDir);

        $limit = min(max((int) $request->get('limit', 500), 1), 1000);
        $commandes = $query->limit($limit)->get();

        return response()->json([
            'success' => true,
            'data' => $commandes->map(function (Commande $c) {
                return $this->formatCommande($c);
            }),
        ]);
    }

    /**
     * Créer une commande
     * POST /api/commandes
     */
    public function store(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        // Log pour débogage
        Log::info('CommandeController::store - Données reçues', [
            'request_data' => $request->all(),
            'user_id' => $user->id,
        ]);

        $validator = Validator::make($request->all(), [
            'table_id' => 'required|exists:tables,id',
            'notes' => 'nullable|string',
            'produits' => 'required|array|min:1',
            'produits.*.produit_id' => 'required|exists:produits,id',
            'produits.*.quantite' => 'required|integer|min:1',
            'produits.*.notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            Log::error('CommandeController::store - Erreur de validation', [
                'errors' => $validator->errors()->toArray(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        DB::beginTransaction();
        try {
            // Vérifier s'il y a déjà une commande active sur cette table
            $existingOrder = Commande::where('table_id', $request->table_id)
                ->whereNotIn('statut', [OrderStatus::Terminee, OrderStatus::Annulee])
                ->first();

            if ($existingOrder) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'Une commande est déjà en cours sur cette table.',
                    'data' => ['existing_order_id' => $existingOrder->id],
                ], 409); // Conflict
            }

            // Créer la commande (lier le client si l'utilisateur en a un, pour la fidélité)
            $commande = Commande::create([
                'table_id' => $request->table_id,
                'user_id' => $user->id,
                'client_id' => $user->client?->id,
                'statut' => OrderStatus::Attente,
                'notes' => $request->notes,
            ]);
            
            Log::info('CommandeController::store - Commande créée', [
                'commande_id' => $commande->id,
            ]);

            // Ajouter les produits
            foreach ($request->produits as $item) {
                $produit = Product::find($item['produit_id']);
                
                if (!$produit) {
                    DB::rollBack();
                    Log::error('CommandeController::store - Produit non trouvé', [
                        'produit_id' => $item['produit_id'] ?? null,
                    ]);
                    return response()->json([
                        'success' => false,
                        'message' => "Le produit avec l'ID {$item['produit_id']} n'existe pas",
                    ], 400);
                }
                
                if (!$produit->isDisponible()) {
                    DB::rollBack();
                    Log::warning('CommandeController::store - Produit non disponible', [
                        'produit_id' => $produit->id,
                        'produit_nom' => $produit->nom,
                    ]);
                    return response()->json([
                        'success' => false,
                        'message' => "Le produit {$produit->nom} n'est pas disponible",
                    ], 400);
                }

                try {
                    $commande->produits()->attach($produit->id, [
                        'quantite' => $item['quantite'],
                        'prix_unitaire' => $produit->prix,
                        'notes' => $item['notes'] ?? null,
                        'statut' => 'envoye', // Directement envoyé à la création
                    ]);
                } catch (\Exception $e) {
                    // Si l'erreur est liée à la colonne 'statut' (migration non lancée)
                    // On essaie sans le champ statut
                    if (str_contains($e->getMessage(), 'statut') || str_contains($e->getMessage(), 'column not found')) {
                        try {
                            $commande->produits()->attach($produit->id, [
                                'quantite' => $item['quantite'],
                                'prix_unitaire' => $produit->prix,
                                'notes' => $item['notes'] ?? null,
                            ]);
                        } catch (\Exception $e2) {
                            Log::error('CommandeController::store - Erreur critique pivot', ['error' => $e2->getMessage()]);
                            throw $e2;
                        }
                    } else {
                        Log::error('CommandeController::store - Erreur attach', ['error' => $e->getMessage()]);
                        throw $e;
                    }
                }
            }

            // Calculer le montant total de la commande
            $commande->calculerMontantTotal();

            // Marquer la table comme occupée
            $table = Table::find($request->table_id);
            if ($table->isLibre()) {
                $table->occuper();
            }

            DB::commit();

            // Notifier le personnel
            $this->notifierPersonnel($commande->fresh()->load(['table', 'produits']), 'create');

            return response()->json([
                'success' => true,
                'message' => 'Commande créée avec succès',
                'data' => $this->formatCommande($commande->fresh()->load(['table', 'user', 'produits'])),
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('CommandeController::store - Exception', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur serveur. Veuillez réessayer plus tard.',
                'error' => config('app.debug') ? $e->getMessage() : 'Erreur interne du serveur',
            ], 500);
        }
    }

    /**
     * Afficher une commande
     * GET /api/commandes/{id}
     */
    public function show($id)
    {
        $commande = Commande::with(['table', 'user', 'produits', 'paiements.facture'])->find($id);

        if (!$commande) {
            return response()->json([
                'success' => false,
                'message' => 'Commande non trouvée',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatCommande($commande),
        ]);
    }

    /**
     * Récupérer la facture d'une commande
     * GET /api/commandes/{id}/facture
     */
    public function getFacture($id)
    {
        $commande = Commande::with(['table', 'user', 'produits', 'client'])->find($id);

        if (!$commande) {
            return response()->json([
                'success' => false,
                'message' => 'Commande non trouvée',
            ], 404);
        }

        // Récupérer le paiement validé de la commande
        $paiementValide = $commande->paiements()->where('statut', \App\Enums\StatutPaiement::Valide)->latest()->first();
        $paiementValide?->loadMissing('user');

        if (!$paiementValide || !$paiementValide->facture) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune facture disponible pour cette commande.',
            ], 404);
        }

        $facture = $paiementValide->facture->load(['commande.table', 'commande.produits', 'paiement']);

        $pv = $paiementValide;
        $montantRecuApi = null;
        $monnaieRendueApi = null;
        if ($pv->moyen_paiement === MoyenPaiement::Especes) {
            $montantRecuApi = $pv->montant_recu !== null ? (float) $pv->montant_recu : null;
            $mr = $pv->monnaie_rendue;
            if ($mr === null && $montantRecuApi !== null) {
                $mr = max(0.0, $montantRecuApi - (float) $pv->montant);
            }
            $monnaieRendueApi = $mr !== null ? (float) $mr : null;
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => (int) $facture->id,
                'numero_facture' => $facture->numero_facture,
                'commande_id' => (int) $facture->commande_id,
                'paiement_id' => (int) $facture->paiement_id,
                'montant_total' => (float) $facture->montant_total,
                'montant_taxe' => (float) $facture->montant_taxe,
                'pdf_url' => $facture->pdf_url,
                'created_at' => $facture->created_at->toIso8601String(),
                'commande' => $this->formatCommande($commande),
                'paiement' => [
                    'id' => (int) $paiementValide->id,
                    'user_id' => $paiementValide->user_id ? (int) $paiementValide->user_id : null,
                    'montant' => (float) $paiementValide->montant,
                    'moyen_paiement' => $paiementValide->moyen_paiement->value,
                    'statut' => $paiementValide->statut->value,
                    'transaction_id' => $paiementValide->transaction_id,
                    'montant_recu' => $montantRecuApi,
                    'monnaie_rendue' => $monnaieRendueApi,
                    'created_at' => $paiementValide->created_at->toIso8601String(),
                    'caissier_name' => $paiementValide->user?->name,
                ],
            ],
        ]);
    }

    /**
     * Mettre à jour une commande (ajouter/modifier produits)
     * PUT/PATCH /api/commandes/{id}
     */
    public function update(Request $request, $id)
    {
        $commande = Commande::find($id);

        if (!$commande) {
            return response()->json([
                'success' => false,
                'message' => 'Commande non trouvée',
            ], 404);
        }

        if (!$commande->peutEtreModifiee()) {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande ne peut plus être modifiée',
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'notes' => 'nullable|string',
            'statut' => 'sometimes|in:attente,preparation,servie,terminee,annulee',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        $commande->update($validator->validated());

        // Gérer l'ajout de produits en mode "Brouillon"
        if ($request->has('produits') && is_array($request->produits)) {
             foreach ($request->produits as $item) {
                 if (isset($item['id']) && isset($item['quantite'])) {
                     $produit = Product::find($item['id']);
                     if ($produit) {
                         // On ajoute sans supprimer les existants (attach vs sync)
                         // Et on met le statut 'brouillon' pour les nouveaux
                         $commande->produits()->attach($produit->id, [
                             'quantite' => $item['quantite'],
                             'prix_unitaire' => $produit->prix,
                             'notes' => $item['notes'] ?? null,
                             'statut' => 'brouillon',
                         ]);
                     }
                 }
             }
             
             // Recalculer le montant total
             $commande->calculerMontantTotal();
        }

        return response()->json([
            'success' => true,
            'message' => 'Commande mise à jour avec succès',
            'data' => $this->formatCommande($commande->fresh()->load(['table', 'user', 'produits'])),
        ]);
    }

    /**
     * Ajouter un produit à une commande existante
     * POST /api/commandes/{id}/produits
     */
    public function addProduit(Request $request, $id)
    {
        $commande = Commande::find($id);

        if (!$commande) {
            return response()->json([
                'success' => false,
                'message' => 'Commande non trouvée',
            ], 404);
        }

        // Vérifier que l'utilisateur est le propriétaire de la commande (pour les clients)
        // Les admins, managers, serveurs et caissiers peuvent modifier n'importe quelle commande
        /** @var \App\Models\User $user */
        $user = $request->user();
        if ($user->hasRole('client') && $commande->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'êtes pas autorisé à modifier cette commande',
            ], 403);
        }

        if (!$commande->peutEtreModifiee()) {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande ne peut plus être modifiée',
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'produit_id' => 'required|exists:produits,id',
            'quantite' => 'required|integer|min:1',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        $produit = Product::find($request->produit_id);

        if (!$produit->isDisponible()) {
            return response()->json([
                'success' => false,
                'message' => "Le produit {$produit->nom} n'est pas disponible",
            ], 400);
        }

        $commande->ajouterProduit($produit, $request->quantite, $request->notes);

        return response()->json([
            'success' => true,
            'message' => 'Produit ajouté avec succès',
            'data' => $this->formatCommande($commande->fresh()->load(['table', 'user', 'produits'])),
        ]);
    }

    /**
     * Retirer un produit d'une commande
     * DELETE /api/commandes/{id}/produits/{produitId}
     */
    public function removeProduit($id, $produitId)
    {
        $commande = Commande::find($id);

        if (!$commande) {
            return response()->json([
                'success' => false,
                'message' => 'Commande non trouvée',
            ], 404);
        }

        if (!$commande->peutEtreModifiee()) {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande ne peut plus être modifiée',
            ], 400);
        }

        $commande->retirerProduit($produitId);

        return response()->json([
            'success' => true,
            'message' => 'Produit retiré avec succès',
            'data' => $this->formatCommande($commande->fresh()->load(['table', 'user', 'produits'])),
        ]);
    }

    /**
     * Lancer les produits en brouillon (valider la commande)
     * POST /api/commandes/{id}/lancer
     */
    public function lancer($id)
    {
        $commande = Commande::find($id);

        if (!$commande) {
            Log::warning("CommandeController::lancer - Commande non trouvée ID: $id");
            return response()->json(['success' => false, 'message' => 'Commande non trouvée'], 404);
        }

        // Récupérer les produits en brouillon AVANT update pour la notification
        $produitsBrouillon = $commande->produits()->wherePivot('statut', 'brouillon')->get();

        // Mettre à jour tous les produits 'brouillon' en 'envoye'
        DB::table('commande_produit')
            ->where('commande_id', $commande->id)
            ->where('statut', 'brouillon')
            ->update(['statut' => 'envoye']);

        // Mettre à jour le statut global de la commande si nécessaire
        // Si la commande était en attente ou servie (ajout de dessert/boisson), elle passe en préparation
        if ($commande->statut === OrderStatus::Attente || $commande->statut === OrderStatus::Servie) {
             $commande->update(['statut' => OrderStatus::Preparation]);
        }
        
        // Recalculer le montant total (par sécurité)
        $commande->calculerMontantTotal();

        // Notifier le personnel (serveur, manager, admin)
        if ($produitsBrouillon->isNotEmpty()) {
            $this->notifierPersonnel($commande->load('table'), 'update', $produitsBrouillon);
        }

        // Notifier le client (celui qui a créé la commande)
        $this->notifierClient($commande);

        return response()->json([
            'success' => true,
            'message' => 'Commande lancée en cuisine !',
            'data' => $this->formatCommande($commande->fresh()->load(['table', 'user', 'produits'])),
        ]);
    }

    /**
     * Marquer les produits non encore servis comme servis (bouton "Servi").
     * Les nouveaux produits ajoutés plus tard par le client restent non servis.
     * POST /api/commandes/{id}/marquer-servi
     */
    public function marquerServi(Request $request, $id)
    {
        $commande = Commande::find($id);

        if (!$commande) {
            return response()->json([
                'success' => false,
                'message' => 'Commande non trouvée',
            ], 404);
        }

        /** @var \App\Models\User $user */
        $user = $request->user();
        if ($user->hasRole('client')) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'êtes pas autorisé à marquer cette commande comme servie',
            ], 403);
        }

        // Marquer tous les produits pas encore servis comme servis
        $updated = DB::table('commande_produit')
            ->where('commande_id', $commande->id)
            ->where(function ($q) {
                $q->where('servi', false)->orWhereNull('servi');
            })
            ->update(['servi' => true]);

        // Mettre à jour le statut de la commande en "servie"
        $commande->update(['statut' => OrderStatus::Servie]);

        return response()->json([
            'success' => true,
            'message' => 'Produits marqués comme servis. Les prochains ajouts du client apparaîtront comme nouveaux.',
            'data' => $this->formatCommande($commande->fresh()->load(['table', 'user', 'produits'])),
        ]);
    }

    /**
     * Changer le statut d'une commande
     * PATCH /api/commandes/{id}/statut
     */
    public function updateStatut(Request $request, $id)
    {
        $commande = Commande::find($id);

        if (!$commande) {
            return response()->json([
                'success' => false,
                'message' => 'Commande non trouvée',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'statut' => 'required|in:attente,preparation,servie,terminee,annulee',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Vérifier que l'utilisateur a les permissions pour changer le statut
        // Les clients ne peuvent pas changer le statut manuellement (sauf lancer)
        /** @var \App\Models\User $user */
        $user = $request->user();
        if ($user->hasRole('client')) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'êtes pas autorisé à modifier le statut de cette commande',
            ], 403);
        }

        $commande->update(['statut' => OrderStatus::from($validator->validated()['statut'])]);

        return response()->json([
            'success' => true,
            'message' => 'Statut mis à jour avec succès',
            'data' => $this->formatCommande($commande->fresh()->load(['table', 'user', 'produits'])),
        ]);
    }

    /**
     * Notifier le client du changement de statut de sa commande
     */
    private function notifierClient(Commande $commande)
    {
        // On récupère l'utilisateur qui a créé la commande
        $client = $commande->user;

        if (!$client) {
            Log::warning("NotifierClient: Pas de client associé à la commande {$commande->id}");
            return;
        }

        if (!$client->fcm_token) {
            Log::warning("NotifierClient: Client {$client->id} n'a pas de token FCM.");
            return;
        }

        $fcmService = app(\App\Services\FCMService::class);
        $tableModel = $commande->table()->first();
        $tableNumber = $tableModel ? $tableModel->numero : 'Inconnue';

        $fcmService->sendToTokens(
            [$client->fcm_token],
            'Commande Lancée 🚀',
            "Votre commande pour la table #{$tableNumber} a été lancée en cuisine.",
            [
                'type' => 'commande_update',
                'commande_id' => (string)$commande->id,
                'statut' => 'preparation'
            ]
        );
    }

    /**
     * Formater une commande pour la réponse
     */
    private function formatCommande(Commande $commande): array
    {
        // Convertir l'enum en string pour l'API
        $statutValue = $commande->statut instanceof OrderStatus 
            ? $commande->statut->value 
            : $commande->statut;
        
        /** @var \App\Models\Table|null $table */
        $table = $commande->table;

        /** @var \App\Models\User|null $user */
        $user = $commande->user;

        return [
            'id' => $commande->id,
            'table_id' => (int) $commande->table_id,
            'table' => $table ? [
                'id' => $table->id,
                'numero' => $table->numero,
                'type' => $table->type instanceof \App\Enums\TableType 
                    ? $table->type->value 
                    : $table->type,
                'capacite' => $table->capacite,
                'statut' => $table->statut instanceof \App\Enums\TableStatus
                    ? $table->statut->value
                    : $table->statut,
                'prix' => $table->prix,
                'prix_par_heure' => $table->prix_par_heure,
                'actif' => $table->actif,
            ] : null,
            'user' => $user ? [
                'id' => $user->id,
                'name' => $user->name,
            ] : null,
            'client' => $commande->client ? [
                'id' => $commande->client->id,
                'nom_complet' => $commande->client->nom_complet,
                'telephone' => $commande->client->telephone,
            ] : null,
            'statut' => $statutValue,
            'statut_display' => $commande->statut_display,
            'montant_total' => (float) $commande->montant_total,
            'reduction_fidelite' => (float) $commande->paiements()
                ->where('moyen_paiement', \App\Enums\MoyenPaiement::PointsFidelite)
                ->where('statut', \App\Enums\StatutPaiement::Valide)
                ->sum('montant'),
            'points_utilises' => (int) $commande->paiements()
                ->where('statut', \App\Enums\StatutPaiement::Valide)
                ->sum('points_utilises'),
            'notes' => $commande->notes,
            'produits' => $commande->produits->map(function($produit) {
                return [
                    'id' => (int) $produit->id,
                    'nom' => $produit->nom,
                    'prix_unitaire' => (float) $produit->pivot->prix_unitaire,
                    'quantite' => (int) $produit->pivot->quantite,
                    'notes' => $produit->pivot->notes,
                    'statut' => $produit->pivot->statut ?? 'envoye',
                    'servi' => (bool) ($produit->pivot->servi ?? false),
                    'sous_total' => (float) ($produit->pivot->prix_unitaire * $produit->pivot->quantite),
                ];
            }),
            'created_at' => $commande->created_at ? $commande->created_at->toIso8601String() : null,
            'updated_at' => $commande->updated_at ? $commande->updated_at->toIso8601String() : null,
        ];
    }

    /**
     * Notifier le personnel (serveur, manager, admin) via FCM
     */
    private function notifierPersonnel(Commande $commande, string $type = 'create', $produits = null)
    {
        try {
            // Utiliser whereHas au lieu du scope role() pour éviter l'erreur "There is no role named X"
            // si un rôle n'existe pas dans la base de données.
            // Vérifier quels rôles existent réellement pour éviter l'exception Spatie
            $rolesToNotify = ['serveur', 'manager', 'admin', 'superadmin'];
            $existingRolesForTokens = \Spatie\Permission\Models\Role::whereIn('name', $rolesToNotify)
                ->where('guard_name', 'web')
                ->pluck('name')
                ->toArray();

            if (empty($existingRolesForTokens)) {
                return;
            }

            $tokens = User::whereHas('roles', function($q) use ($existingRolesForTokens) {
                $q->whereIn('name', $existingRolesForTokens);
            })
            ->whereNotNull('fcm_token')
            ->pluck('fcm_token')
            ->toArray();

            if (empty($tokens)) {
                return;
            }

            $tableModel = $commande->table()->first();
            $tableNumero = $tableModel ? $tableModel->numero : 'Inconnue';
            $title = ($type === 'create') 
                ? "Nouvelle Commande - Table $tableNumero"
                : "Mise à jour Commande - Table $tableNumero";

            // Construire le corps du message
            $body = "";
            /** @var \Illuminate\Database\Eloquent\Collection $items */
            $items = $produits ?? $commande->produits;
            
            foreach ($items as $produit) {
                $nom = $produit->nom;
                $qte = $produit->pivot->quantite;
                $body .= "{$qte}x {$nom}\n";
            }

            // Tronquer si trop long
            if (mb_strlen($body) > 100) {
                $body = mb_substr($body, 0, 97) . '...';
            }
            
            if (empty($body)) {
                $body = "Détails de la commande mis à jour.";
            }

            // Données supplémentaires pour la navigation in-app
            $data = [
                'type' => 'commande_update',
                'commande_id' => (string) $commande->id,
                'table_id' => (string) $commande->table_id,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ];

            $this->fcmService->sendToTokens($tokens, $title, $body, $data);

            // Enregistrer en base pour la liste notifications (lu / non lu)
            // Récupérer les tokens des personnels (Serveurs, Managers, Admin)
            $rolesToNotify = ['serveur', 'manager', 'admin', 'superadmin'];
            
            // On vérifie quels rôles existent réellement en base pour éviter les exceptions Spatie
            $existingRoles = \Spatie\Permission\Models\Role::whereIn('name', $rolesToNotify)
                ->where('guard_name', 'web')
                ->pluck('name')
                ->toArray();

            if (empty($existingRoles)) {
                 Log::warning("Aucun rôle de notification trouvé en base (" . implode(', ', $rolesToNotify) . "). Les notifications ne seront pas envoyées.");
                 return;
            }

            $users = User::whereHas('roles', function ($q) use ($existingRoles) {
                $q->whereIn('name', $existingRoles);
            })->whereNotNull('fcm_token')->get();

            foreach ($users as $u) {
                /** @var User $u */
                $u->notifications()->create([
                    'type' => 'commande',
                    'title' => $title,
                    'body' => $body,
                    'data' => $data,
                ]);
            }
        } catch (\Exception $e) {
            Log::error("Erreur lors de l'envoi de la notification FCM: " . $e->getMessage());
        }
    }
}
