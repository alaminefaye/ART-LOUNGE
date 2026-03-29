<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Paiement;
use App\Models\Commande;
use App\Models\Facture;
use App\Models\Table;
use App\Enums\StatutPaiement;
use App\Enums\MoyenPaiement;
use App\Enums\OrderStatus;
use App\Enums\TableStatus;
use App\Models\CaisseSession;
use App\Services\FactureService;
use App\Services\FCMService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\DB;

class PaiementController extends Controller
{
    protected $factureService;
    protected $fcmService;

    public function __construct(FactureService $factureService, FCMService $fcmService)
    {
        $this->factureService = $factureService;
        $this->fcmService = $fcmService;
    }

    /**
     * Liste tous les paiements
     */
    public function index()
    {
        $paiements = Paiement::with(['commande.table', 'user', 'facture'])->get();
        return response()->json([
            'success' => true,
            'data' => $paiements,
        ]);
    }

    /**
     * Affiche un paiement spécifique
     */
    public function show(Paiement $paiement)
    {
        return response()->json([
            'success' => true,
            'data' => $paiement->load(['commande.table', 'commande.produits', 'user', 'facture']),
        ]);
    }

    /**
     * Initie un nouveau paiement
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'commande_id' => 'required|exists:commandes,id',
            'moyen_paiement' => ['required', Rule::enum(MoyenPaiement::class)],
            'points_utilises' => 'nullable|integer|min:0',
            'transaction_id' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated, $request) {
            $commande = Commande::with('table', 'client')->findOrFail($validated['commande_id']);
            $user = $request->user();
            $moyenPaiement = MoyenPaiement::from($validated['moyen_paiement']);
            $pointsUtilises = (int) ($validated['points_utilises'] ?? 0);

            // Si c'est un membre du staff, vérifier la session de caisse
            $session = null;
            if ($user->hasAnyRole(['admin', 'manager', 'caissier'])) {
                $session = CaisseSession::where('user_id', $user->id)
                    ->where('statut', 'ouverte')
                    ->first();

                if (!$session) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Veuillez ouvrir une session de caisse avant d\'encaisser.',
                    ], 403);
                }
            }

            if ($commande->paiements()->where('statut', StatutPaiement::Valide)->sum('montant') >= (float) $commande->montant_total) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette commande a déjà été payée.',
                ], 409);
            }

            $allowedForClient = [MoyenPaiement::Wave, MoyenPaiement::OrangeMoney, MoyenPaiement::PointsFidelite];
            if ($user->hasRole('client') && !in_array($moyenPaiement, $allowedForClient)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Moyen de paiement non autorisé depuis l\'app. Utilisez les points, Wave ou Orange Money, ou réglez en espèces au serveur.',
                ], 403);
            }

            if ($user->hasRole('client') && $commande->user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous n\'êtes pas autorisé à payer cette commande.',
                ], 403);
            }

            // Paiement en points de fidélité (client app)
            if ($moyenPaiement === MoyenPaiement::PointsFidelite) {
                $client = $user->client;
                if (!$client) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Aucun compte fidélité associé.',
                    ], 403);
                }
                $settings = \App\Models\FidelitySetting::get();
                if (!$settings->actif) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Le paiement en points est désactivé.',
                    ], 400);
                }
                if ($pointsUtilises <= 0) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Indiquez le nombre de points à utiliser.',
                    ], 422);
                }
                if ($client->points_fidelite < $pointsUtilises) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Solde insuffisant. Vous avez ' . $client->points_fidelite . ' points.',
                    ], 422);
                }
                $reductionFcfa = (float) $settings->fcfaPourPoints($pointsUtilises);
                $montantPoints = min($reductionFcfa, (float) $commande->montant_total);
                $dejaPaye = (float) $commande->paiements()->where('statut', StatutPaiement::Valide)->sum('montant');
                $resteDu = (float) $commande->montant_total - $dejaPaye;
                if ($montantPoints > $resteDu) {
                    $montantPoints = $resteDu;
                }

                $paiement = Paiement::create([
                    'commande_id' => $commande->id,
                    'user_id' => $user->id,
                    'client_id' => $client->id,
                    'caisse_session_id' => $session ? $session->id : null,
                    'moyen_paiement' => MoyenPaiement::PointsFidelite,
                    'montant' => $montantPoints,
                    'statut' => StatutPaiement::Valide,
                    'points_utilises' => $pointsUtilises,
                    'notes' => $validated['notes'] ?? null,
                ]);

                app(\App\Services\FidelityService::class)->debiterPoints(
                    $client,
                    $pointsUtilises,
                    'Paiement commande #' . $commande->id,
                    $commande->id
                );

                $totalPaye = (float) $commande->paiements()->where('statut', StatutPaiement::Valide)->sum('montant');
                if ($totalPaye >= (float) $commande->montant_total) {
                    $commande->update(['statut' => OrderStatus::Terminee]);
                    $commande->table->liberer();
                    $montantReel = app(\App\Services\FidelityService::class)->montantPayeReel($commande);
                    if ($montantReel > 0 && $commande->client_id) {
                        app(\App\Services\FidelityService::class)->crediterPointsPourPaiement($commande, $montantReel);
                    }
                    $facture = $this->factureService->genererFacture($commande, $paiement);
                    try {
                        $this->fcmService->notifyClientPaymentValidated($commande, $facture);
                    } catch (\Throwable $e) {
                        \Log::warning('FCM: échec notification paiement client', ['error' => $e->getMessage()]);
                    }
                    return response()->json([
                        'success' => true,
                        'message' => 'Paiement en points enregistré. Commande réglée.',
                        'data' => $paiement->load(['commande', 'facture']),
                        'facture' => $facture,
                    ], 201);
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Points utilisés. Il reste ' . number_format((float) $commande->montant_total - $totalPaye, 0, '', ' ') . ' FCFA à régler.',
                    'data' => $paiement->load(['commande', 'facture']),
                    'reste_a_payer' => (float) $commande->montant_total - $totalPaye,
                ], 201);
            }

            // Autres moyens (Wave, OM, etc.)
            $paiement = Paiement::create([
                'commande_id' => $commande->id,
                'user_id' => $user->id,
                'caisse_session_id' => $session ? $session->id : null,
                'montant' => $commande->montant_total,
                'moyen_paiement' => $moyenPaiement,
                'statut' => StatutPaiement::EnAttente,
                'transaction_id' => $validated['transaction_id'] ?? null,
                'notes' => $validated['notes'] ?? null,
            ]);

            $table = Table::find($commande->table_id);
            if ($table && $table->statut !== TableStatus::EnPaiement) {
                $table->enPaiement();
            }

            return response()->json([
                'success' => true,
                'message' => 'Paiement initié avec succès',
                'data' => $paiement->load(['commande', 'facture']),
            ], 201);
        });
    }

    /**
     * Valide un paiement (pour mobile money - Wave, Orange Money)
     * Le client confirme d'abord, puis le gérant valide
     */
    public function valider(Paiement $paiement)
    {
        if ($paiement->statut === StatutPaiement::Valide) {
            return response()->json([
                'success' => false,
                'message' => 'Ce paiement est déjà validé.',
            ], 409);
        }

        // Vérifier que c'est un paiement mobile money (Wave ou Orange Money)
        if (!in_array($paiement->moyen_paiement, [MoyenPaiement::Wave, MoyenPaiement::OrangeMoney])) {
            return response()->json([
                'success' => false,
                'message' => 'Cette méthode de validation ne s\'applique qu\'aux paiements mobile money.',
            ], 400);
        }

        return DB::transaction(function () use ($paiement) {
            // Valider le paiement
            $paiement->valider();

            // Générer la facture
            $facture = $this->factureService->genererFacture($paiement->commande, $paiement);

            // Mettre à jour le statut de la commande
            $paiement->commande->update(['statut' => OrderStatus::Terminee]);

            $table = Table::find($paiement->commande->table_id);
            if ($table) {
                $table->liberer();
            }

            $this->fcmService->notifyClientPaymentValidated($paiement->commande, $facture);

            return response()->json([
                'success' => true,
                'message' => 'Paiement validé avec succès',
                'data' => [
                    'paiement' => $paiement->fresh()->load('facture'),
                    'facture' => $facture,
                ],
            ]);
        });
    }

    /**
     * Client confirme un paiement mobile money (Wave, Orange Money)
     * POST /api/paiements/{id}/confirmer
     */
    public function confirmer(Request $request, Paiement $paiement)
    {
        if ($paiement->statut !== StatutPaiement::EnAttente) {
            return response()->json([
                'success' => false,
                'message' => 'Ce paiement ne peut plus être confirmé.',
            ], 400);
        }

        // Vérifier que c'est un paiement mobile money
        if (!in_array($paiement->moyen_paiement, [MoyenPaiement::Wave, MoyenPaiement::OrangeMoney])) {
            return response()->json([
                'success' => false,
                'message' => 'Cette méthode de confirmation ne s\'applique qu\'aux paiements mobile money.',
            ], 400);
        }

        // Vérifier que le client est le propriétaire de la commande
        $user = $request->user();
        if ($user->hasRole('client') && $paiement->commande->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'êtes pas autorisé à confirmer ce paiement.',
            ], 403);
        }

        $validated = $request->validate([
            'transaction_id' => 'required|string|max:255',
        ]);

        // Mettre à jour le transaction_id
        $paiement->update(['transaction_id' => $validated['transaction_id']]);

        // Le paiement reste en attente, le gérant devra le valider
        return response()->json([
            'success' => true,
            'message' => 'Paiement confirmé. En attente de validation par le gérant.',
            'data' => $paiement->fresh()->load(['commande', 'facture']),
        ]);
    }

    /**
     * Marque un paiement comme échoué
     */
    public function echouer(Paiement $paiement)
    {
        if ($paiement->statut === StatutPaiement::Valide) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de marquer comme échoué un paiement déjà validé.',
            ], 409);
        }

        return DB::transaction(function () use ($paiement) {
            $paiement->echouer();

            $table = Table::find($paiement->commande->table_id);
            if ($table) {
                $table->occuper();
            }

            return response()->json([
                'success' => true,
                'message' => 'Paiement marqué comme échoué',
                'data' => $paiement->fresh(),
            ]);
        });
    }

    /**
     * Annule un paiement
     */
    public function annuler(Paiement $paiement)
    {
        if ($paiement->statut === StatutPaiement::Valide) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible d\'annuler un paiement validé.',
            ], 409);
        }

        return DB::transaction(function () use ($paiement) {
            $paiement->update(['statut' => StatutPaiement::Annule]);

            $table = Table::find($paiement->commande->table_id);
            if ($table) {
                $table->occuper();
            }

            return response()->json([
                'success' => true,
                'message' => 'Paiement annulé',
                'data' => $paiement->fresh(),
            ]);
        });
    }

    /**
     * Télécharge la facture d'un paiement
     */
    public function telechargerFacture(Paiement $paiement)
    {
        if (!$paiement->facture) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune facture disponible pour ce paiement.',
            ], 404);
        }

        return $this->factureService->telechargerFacture($paiement->facture);
    }

    /**
     * Workflow complet de paiement espèces (création + validation automatique)
     */
    public function payerEspeces(Request $request)
    {
        $validated = $request->validate([
            'commande_id' => 'required|exists:commandes,id',
            'montant_recu' => 'required|numeric|min:0',
            'client_id' => 'nullable|exists:clients,id',
            'points_utilises' => 'nullable|integer|min:0',
            'notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated, $request) {
            $user = $request->user();
            
            // Vérifier la session de caisse pour le staff
            $session = CaisseSession::where('user_id', $user->id)
                ->where('statut', 'ouverte')
                ->first();

            if (!$session) {
                return response()->json([
                    'success' => false,
                    'message' => 'Veuillez ouvrir une session de caisse avant d\'encaisser.',
                ], 403);
            }

            $commande = Commande::with(['table', 'produits', 'client'])->findOrFail($validated['commande_id']);

            // Vérifier si la commande n'est pas déjà payée
            if ($commande->paiements()->where('statut', StatutPaiement::Valide)->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette commande a déjà été payée.',
                ], 409);
            }

            $montantTotal = (float) $commande->montant_total;
            $reductionFidelite = 0.0;
            $pointsUtilises = (int) ($validated['points_utilises'] ?? 0);

            // Gestion de la fidélité si demandée
            if ($pointsUtilises > 0 && $validated['client_id']) {
                $client = \App\Models\Client::findOrFail($validated['client_id']);
                if ($client->points_fidelite < $pointsUtilises) {
                    return response()->json(['success' => false, 'message' => 'Points insuffisants.'], 422);
                }

                $settings = \App\Models\FidelitySetting::get();
                $reductionFidelite = (float) $settings->fcfaPourPoints($pointsUtilises);
                
                // Débiter les points
                app(\App\Services\FidelityService::class)->debiterPoints(
                    $client,
                    $pointsUtilises,
                    'Réduction fidélité sur commande #' . $commande->id,
                    $commande->id
                );
                
                // Si la réduction dépasse le montant, on plafonne
                if ($reductionFidelite > $montantTotal) {
                    $reductionFidelite = $montantTotal;
                }
            }

            $netAPayer = $montantTotal - $reductionFidelite;

            // Vérifier le montant reçu (comparé au net à payer)
            if ($validated['montant_recu'] < $netAPayer) {
                return response()->json([
                    'success' => false,
                    'message' => 'Le montant reçu est insuffisant.',
                    'data' => [
                        'montant_total' => $montantTotal,
                        'reduction' => $reductionFidelite,
                        'net_a_payer' => $netAPayer,
                        'montant_recu' => $validated['montant_recu'],
                        'manquant' => $netAPayer - $validated['montant_recu'],
                    ],
                ], 422);
            }

            // Créer le paiement principal (Espèces)
            $paiement = Paiement::create([
                'commande_id' => $commande->id,
                'user_id' => $user->id,
                'client_id' => $validated['client_id'] ?? $commande->client_id,
                'caisse_session_id' => $session->id,
                'montant' => $netAPayer,
                'moyen_paiement' => MoyenPaiement::Especes,
                'statut' => StatutPaiement::Valide,
                'montant_recu' => $validated['montant_recu'],
                'points_utilises' => $pointsUtilises, // On log les points sur ce paiement
                'notes' => $validated['notes'] ?? null,
            ]);

            // Si points utilisés, on peut aussi créer un paiement "virtuel" de type Points pour la traçabilité
            if ($reductionFidelite > 0) {
                Paiement::create([
                    'commande_id' => $commande->id,
                    'user_id' => $user->id,
                    'client_id' => $validated['client_id'],
                    'caisse_session_id' => $session->id,
                    'montant' => $reductionFidelite,
                    'moyen_paiement' => MoyenPaiement::PointsFidelite,
                    'statut' => StatutPaiement::Valide,
                    'points_utilises' => $pointsUtilises,
                    'notes' => 'Réduction appliquée',
                ]);
            }

            // Calculer la monnaie sur le paiement espèces
            $paiement->calculerMonnaie();

            // Générer la facture (elle prendra en compte le montant du paiement principal + points si FactureService est bien fait)
            $facture = $this->factureService->genererFacture($commande, $paiement);

            // Terminer la commande
            $commande->update(['statut' => OrderStatus::Terminee]);
            if ($validated['client_id']) {
                $commande->update(['client_id' => $validated['client_id']]);
            }

            $table = Table::find($commande->table_id);
            if ($table) {
                $table->liberer();
            }

            // Créditer de nouveaux points sur le montant RÉELlement payé (net)
            if ($netAPayer > 0 && ($validated['client_id'] ?? $commande->client_id)) {
                $targetClient = \App\Models\Client::find($validated['client_id'] ?? $commande->client_id);
                if ($targetClient) {
                    app(\App\Services\FidelityService::class)->crediterPointsPourPaiement($commande, $netAPayer);
                }
            }

            $this->fcmService->notifyClientPaymentValidated($commande, $facture);

            return response()->json([
                'success' => true,
                'message' => 'Paiement espèces effectué avec succès',
                'data' => [
                    'paiement' => $paiement->fresh()->load('facture'),
                    'facture' => $facture,
                    'monnaie_rendue' => $paiement->monnaie_rendue,
                    'reduction_fidelite' => $reductionFidelite,
                ],
            ], 201);
        });
    }
}
