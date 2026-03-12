<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Commande;
use App\Models\Paiement;
use App\Models\Facture;
use App\Enums\MoyenPaiement;
use App\Enums\StatutPaiement;
use App\Enums\OrderStatus;
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

        $commande->load(['table', 'produits']);
        $moyensPaiement = MoyenPaiement::cases();

        return view('caisse.payer', compact('commande', 'moyensPaiement'));
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
            'moyen_paiement' => ['required', Rule::enum(MoyenPaiement::class)],
            'montant_recu' => 'nullable|numeric|min:0',
            'reference_transaction' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
        ]);

        if ($commande->statut === OrderStatus::Terminee) {
            // Vérifier si une facture existe déjà pour cette commande
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

        return DB::transaction(function () use ($validated, $request, $commande) {
            $montantAPayer = $commande->montant_total;
            $moyenPaiement = MoyenPaiement::from($validated['moyen_paiement']);
            $montantRecu = $validated['montant_recu'] ?? $montantAPayer;
            $monnaieRendue = 0;
            $statutPaiement = StatutPaiement::EnAttente;

            // Validation selon le moyen de paiement
            if ($moyenPaiement === MoyenPaiement::Especes) {
                if ($montantRecu < $montantAPayer) {
                    return back()->with('error', 'Le montant reçu est insuffisant.')
                                 ->withInput();
                }
                $monnaieRendue = $montantRecu - $montantAPayer;
                $statutPaiement = StatutPaiement::Valide;
            } else {
                // Pour mobile money et carte bancaire
                if (empty($validated['reference_transaction'])) {
                    return back()->with('error', 'La référence de transaction est requise pour ce moyen de paiement.')
                                 ->withInput();
                }
                $statutPaiement = StatutPaiement::Valide; // On suppose que c'est validé immédiatement
            }

            // Créer le paiement
            $paiement = Paiement::create([
                'commande_id' => $commande->id,
                'user_id' => auth()->id(),
                'moyen_paiement' => $moyenPaiement,
                'montant' => $montantAPayer,
                'montant_recu' => $montantRecu,
                'monnaie_rendue' => $monnaieRendue,
                'statut' => $statutPaiement,
                'transaction_id' => $validated['reference_transaction'] ?? null,
                'notes' => $validated['notes'] ?? null,
            ]);

            // Mettre à jour la commande
            $commande->statut = OrderStatus::Terminee;
            $commande->save();

            // Libérer la table
            $commande->table->liberer();

            try {
                // Générer la facture
                $facture = $this->factureService->genererFacture($commande, $paiement);

                // Notifier le client sur l'app mobile (reçu + note de satisfaction)
                try {
                    $this->fcmService->notifyClientPaymentValidated($commande, $facture);
                } catch (\Throwable $e) {
                    \Log::warning('FCM: échec envoi notification paiement au client', [
                        'commande_id' => $commande->id,
                        'error' => $e->getMessage(),
                    ]);
                }

                // Utiliser redirect avec code 303 (See Other) pour forcer une nouvelle requête GET
                return redirect()->route('caisse.facture', $facture)
                                ->with('success', 'Paiement enregistré avec succès !')
                                ->setStatusCode(303);
            } catch (\Exception $e) {
                // En cas d'erreur lors de la génération de la facture, rediriger quand même vers la caisse
                \Log::error('Erreur lors de la génération de la facture', [
                    'commande_id' => $commande->id,
                    'paiement_id' => $paiement->id,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                ]);
                
                return redirect()->route('caisse.index')
                                ->with('warning', 'Paiement enregistré avec succès, mais erreur lors de la génération de la facture. Le paiement a été enregistré (ID: ' . $paiement->id . ').');
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
