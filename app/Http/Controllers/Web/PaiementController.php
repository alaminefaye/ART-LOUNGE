<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Commande;
use App\Models\Paiement;
use App\Models\Facture;
use App\Enums\MoyenPaiement;
use App\Enums\StatutPaiement;
use App\Enums\OrderStatus;
use App\Models\Client;
use App\Models\FidelitySetting;
use App\Services\FactureService;
use App\Services\FCMService;
use App\Services\FidelityService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\DB;

class PaiementController extends Controller
{
    protected $factureService;
    protected $fcmService;
    protected $fidelityService;

    public function __construct(FactureService $factureService, FCMService $fcmService, FidelityService $fidelityService)
    {
        $this->factureService = $factureService;
        $this->fcmService = $fcmService;
        $this->fidelityService = $fidelityService;
    }

    /**
     * Interface de caisse - Liste des commandes à payer
     */
    public function caisse()
    {
        $commandesEnAttente = Commande::with(['table', 'user', 'produits'])
            ->whereIn('statut', [OrderStatus::Servie, OrderStatus::Preparation, OrderStatus::Attente])
            ->orderBy('created_at', 'desc')
            ->get();

        return view('caisse.index', compact('commandesEnAttente'));
    }

    /**
     * Afficher le formulaire de paiement pour une commande
     */
    public function payer(Commande $commande)
    {
        if ($commande->statut === OrderStatus::Terminee) {
            return redirect()->route('caisse.index')
                            ->with('error', 'Cette commande a déjà été payée.');
        }

        $commande->load(['table', 'produits', 'client']);
        $moyensPaiement = MoyenPaiement::cases();
        $clients = Client::orderBy('nom')->orderBy('prenom')->get();
        $fidelitySettings = FidelitySetting::get();

        return view('caisse.payer', compact('commande', 'moyensPaiement', 'clients', 'fidelitySettings'));
    }

    /**
     * Traiter un paiement
     */
    public function traiterPaiement(Request $request, Commande $commande)
    {
        // Si c'est une requête GET (rafraîchissement de page ou retour navigateur), rediriger
        if ($request->isMethod('GET')) {
            // Si la commande est déjà payée, rediriger vers la facture si elle existe
            if ($commande->statut === OrderStatus::Terminee) {
                $facture = $commande->paiements()->where('statut', \App\Enums\StatutPaiement::Valide)
                    ->latest()
                    ->first()
                    ?->facture;
                
                if ($facture) {
                    return redirect()->route('caisse.facture', $facture)
                                    ->with('info', 'Cette commande a déjà été payée.');
                }
            }
            
            // Sinon, rediriger vers la page de paiement
            return redirect()->route('caisse.payer', $commande)
                            ->with('info', 'Veuillez utiliser le formulaire de paiement.');
        }

        $validated = $request->validate([
            'client_id' => 'nullable|exists:clients,id',
            'points_utilises' => 'nullable|integer|min:0',
            'moyen_paiement' => ['required', Rule::enum(MoyenPaiement::class)],
            'montant_recu' => 'nullable|numeric|min:0',
            'reference_transaction' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
        ]);

        if ($commande->statut === OrderStatus::Terminee) {
            $facture = $commande->paiements()->where('statut', \App\Enums\StatutPaiement::Valide)
                ->latest()
                ->first()
                ?->facture;
            if ($facture) {
                return redirect()->route('caisse.facture', $facture)
                                ->with('error', 'Cette commande a déjà été payée.');
            }
            return redirect()->route('caisse.index')
                            ->with('error', 'Cette commande a déjà été payée.');
        }

        $pointsUtilises = (int) ($validated['points_utilises'] ?? 0);
        $moyenPaiement = MoyenPaiement::from($validated['moyen_paiement']);

        if ($pointsUtilises > 0) {
            if (empty($validated['client_id'])) {
                return back()->with('error', 'Veuillez sélectionner un client pour utiliser les points de fidélité.')->withInput();
            }
            $client = Client::findOrFail($validated['client_id']);
            if ($client->points_fidelite < $pointsUtilises) {
                return back()->with('error', 'Le client n\'a que ' . $client->points_fidelite . ' points.')->withInput();
            }
            if ($moyenPaiement === MoyenPaiement::PointsFidelite && $pointsUtilises <= 0) {
                return back()->with('error', 'Indiquez le nombre de points à utiliser.')->withInput();
            }
        }

        return DB::transaction(function () use ($validated, $commande, $pointsUtilises, $moyenPaiement) {
            $settings = FidelitySetting::get();
            $montantTotal = (float) $commande->montant_total;
            $reductionFcfa = $pointsUtilises > 0 ? (float) $settings->fcfaPourPoints($pointsUtilises) : 0;
            $resteAPayer = $montantTotal - $reductionFcfa;

            if ($resteAPayer < 0) {
                return back()->with('error', 'Les points couvrent plus que le montant total. Réduisez le nombre de points.')->withInput();
            }

            $paiementPourFacture = null;

            // Paiement en points (partiel ou total)
            if ($pointsUtilises > 0) {
                $client = Client::findOrFail($validated['client_id']);
                $montantPoints = min($reductionFcfa, $montantTotal);
                Paiement::create([
                    'commande_id' => $commande->id,
                    'user_id' => auth()->id(),
                    'client_id' => $client->id,
                    'moyen_paiement' => MoyenPaiement::PointsFidelite,
                    'montant' => $montantPoints,
                    'statut' => StatutPaiement::Valide,
                    'points_utilises' => $pointsUtilises,
                    'notes' => $validated['notes'] ?? null,
                ]);
                $this->fidelityService->debiterPoints(
                    $client,
                    $pointsUtilises,
                    'Paiement commande #' . $commande->id,
                    $commande->id
                );
                $paiementPourFacture = $commande->paiements()->latest()->first();
            }

            // Lier le client à la commande pour attribution des points
            if (!empty($validated['client_id'])) {
                $commande->client_id = $validated['client_id'];
                $commande->save();
            }

            // Paiement du reste (espèces, carte, etc.)
            if ($resteAPayer > 0) {
                if ($moyenPaiement === MoyenPaiement::PointsFidelite) {
                    return back()->with('error', 'Il reste ' . number_format($resteAPayer, 0, '', ' ') . ' FCFA à payer. Choisissez un autre moyen pour le reste.')->withInput();
                }
                $montantRecu = (float) ($validated['montant_recu'] ?? $resteAPayer);
                $monnaieRendue = 0;
                if ($moyenPaiement === MoyenPaiement::Especes) {
                    if ($montantRecu < $resteAPayer) {
                        return back()->with('error', 'Le montant reçu est insuffisant.')->withInput();
                    }
                    $monnaieRendue = $montantRecu - $resteAPayer;
                } else {
                    if (empty($validated['reference_transaction'])) {
                        return back()->with('error', 'Référence de transaction requise.')->withInput();
                    }
                }
                $paiementPourFacture = Paiement::create([
                    'commande_id' => $commande->id,
                    'user_id' => auth()->id(),
                    'client_id' => $validated['client_id'] ?? null,
                    'moyen_paiement' => $moyenPaiement,
                    'montant' => $resteAPayer,
                    'montant_recu' => $montantRecu,
                    'monnaie_rendue' => $monnaieRendue,
                    'statut' => StatutPaiement::Valide,
                    'transaction_id' => $validated['reference_transaction'] ?? null,
                    'notes' => $validated['notes'] ?? null,
                ]);
            }

            $commande->statut = OrderStatus::Terminee;
            $commande->save();
            $commande->table->liberer();

            // Créditer les points pour la part payée en argent réel
            $montantReel = $this->fidelityService->montantPayeReel($commande);
            if ($montantReel > 0 && $commande->client_id) {
                $this->fidelityService->crediterPointsPourPaiement($commande, $montantReel);
            }

            try {
                $facture = $this->factureService->genererFacture($commande, $paiementPourFacture);
                try {
                    $this->fcmService->notifyClientPaymentValidated($commande, $facture);
                } catch (\Throwable $e) {
                    \Log::warning('FCM: échec envoi notification paiement au client', ['commande_id' => $commande->id, 'error' => $e->getMessage()]);
                }
                return redirect()->route('caisse.facture', $facture)
                    ->with('success', 'Paiement enregistré avec succès !')
                    ->setStatusCode(303);
            } catch (\Exception $e) {
                \Log::error('Erreur génération facture', ['commande_id' => $commande->id, 'error' => $e->getMessage()]);
                return redirect()->route('caisse.index')
                    ->with('warning', 'Paiement enregistré. Erreur lors de la génération de la facture.');
            }
        });
    }

    /**
     * Afficher une facture
     */
    public function afficherFacture(Facture $facture)
    {
        $facture->load(['commande.table', 'commande.produits', 'paiement']);
        return view('caisse.facture', compact('facture'));
    }

    /**
     * Télécharger le PDF d'une facture
     */
    public function telechargerFacture(Facture $facture)
    {
        if (!$facture->fichier_pdf) {
            return back()->with('error', 'Aucun fichier PDF disponible pour cette facture.');
        }

        try {
            return $this->factureService->telechargerFacture($facture);
        } catch (\Exception $e) {
            \Log::error('Erreur lors du téléchargement de la facture', [
                'facture_id' => $facture->id,
                'error' => $e->getMessage(),
            ]);
            
            return back()->with('error', 'Erreur lors du téléchargement du PDF de la facture.');
        }
    }

    /**
     * Historique des paiements
     */
    public function historique()
    {
        $paiements = Paiement::with(['commande.table', 'user', 'facture'])
                            ->orderBy('created_at', 'desc')
                            ->paginate(20);

        return view('caisse.historique', compact('paiements'));
    }
}
