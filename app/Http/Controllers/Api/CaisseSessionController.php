<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CaisseSession;
use App\Models\Paiement;
use App\Enums\StatutPaiement;
use App\Enums\MoyenPaiement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CaisseSessionController extends Controller
{
    /**
     * Liste des sessions de l'utilisateur
     */
    public function index(Request $request)
    {
        $sessions = $request->user()->caisseSessions()
            ->orderBy('created_at', 'desc')
            ->paginate(10);

        return response()->json([
            'success' => true,
            'data' => $sessions
        ]);
    }

    /**
     * Session active de l'utilisateur
     */
    public function current(Request $request)
    {
        $session = $request->user()->caisseSessions()
            ->where('statut', 'ouverte')
            ->first();

        return response()->json([
            'success' => true,
            'data' => $session
        ]);
    }

    /**
     * Ouvrir une session
     */
    public function ouvrir(Request $request)
    {
        $validated = $request->validate([
            'solde_ouverture' => 'required|numeric|min:0',
        ]);

        $user = $request->user();

        // Vérifier s'il y a déjà une session ouverte
        $existingSession = $user->caisseSessions()->where('statut', 'ouverte')->first();
        if ($existingSession) {
            return response()->json([
                'success' => false,
                'message' => 'Vous avez déjà une session ouverte.'
            ], 422);
        }

        $session = CaisseSession::create([
            'user_id' => $user->id,
            'solde_ouverture' => $validated['solde_ouverture'],
            'statut' => 'ouverte',
            'opened_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Session ouverte avec succès.',
            'data' => $session
        ], 201);
    }

    /**
     * Bilan de la session active
     */
    public function bilan(Request $request)
    {
        $session = $request->user()->caisseSessions()
            ->where('statut', 'ouverte')
            ->first();

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune session ouverte.'
            ], 404);
        }

        $totaux = Paiement::where('caisse_session_id', $session->id)
            ->where('statut', StatutPaiement::Valide->value)
            ->select('moyen_paiement', DB::raw('SUM(montant) as total'))
            ->groupBy('moyen_paiement')
            ->get();

        $totalVentes = $totaux->sum('total');
        
        // Calculer uniquement ce qui doit être physiquement en caisse (on exclut les points de fidélité)
        // Correction du TypeError : Gestion robuste que $t->moyen_paiement soit un Enum ou une String
        $totalLiquide = $totaux->filter(function($t) {
            $val = $t->moyen_paiement instanceof MoyenPaiement ? $t->moyen_paiement->value : (string)$t->moyen_paiement;
            return strcasecmp($val, MoyenPaiement::PointsFidelite->value) !== 0;
        })->sum('total');

        $totalPointsMontant = $totaux->filter(function($t) {
            $val = $t->moyen_paiement instanceof MoyenPaiement ? $t->moyen_paiement->value : (string)$t->moyen_paiement;
            return strcasecmp($val, MoyenPaiement::PointsFidelite->value) === 0;
        })->sum('total');
        
        // Tous les détails de paiements
        $transactions = Paiement::where('caisse_session_id', $session->id)
            ->where('statut', StatutPaiement::Valide->value)
            ->with([
                'client:id,nom,prenom',
                'commande.table:id,numero',
                'commande.produits.produit:id,nom',
                'commande.serveur:id,nom,prenom',
            ])
            ->select('id', 'client_id', 'montant', 'moyen_paiement', 'points_utilises', 'commande_id', 'created_at')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'session'                     => $session,
                'solde_ouverture'             => $session->solde_ouverture,
                'repartition'                 => $totaux,
                'total_ventes'                => $totalVentes,
                'total_liquide'               => $totalLiquide,
                'total_points_fidelite_montant' => $totalPointsMontant,
                'total_attendu_caisse'         => $session->solde_ouverture + $totalLiquide,
                'points_details'              => $transactions->where('moyen_paiement', MoyenPaiement::PointsFidelite->value)->values(),
                'transactions'                => $transactions
            ]
        ]);
    }

    /**
     * Fermer la session
     */
    public function fermer(Request $request)
    {
        $validated = $request->validate([
            'solde_fermeture_reel' => 'required|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $user = $request->user();
        $session = $user->caisseSessions()->where('statut', 'ouverte')->first();

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune session ouverte à fermer.'
            ], 422);
        }

        // Bloquer si des commandes actives (non payées) existent depuis l'ouverture
        $commandesActives = \App\Models\Commande::whereNotIn('statut', ['terminee', 'annulee'])
            ->where('created_at', '>=', $session->opened_at)
            ->count();

        if ($commandesActives > 0) {
            return response()->json([
                'success' => false,
                'message' => "Impossible de fermer la caisse : $commandesActives commande(s) ne sont pas encore payée(s). Réglez toutes les commandes avant de clôturer.",
                'commandes_actives' => $commandesActives,
            ], 422);
        }

        // Calculer le total liquide attendu (hors points)
        $totalLiquide = Paiement::where('caisse_session_id', $session->id)
            ->where('statut', StatutPaiement::Valide->value)
            ->where('moyen_paiement', '!=', MoyenPaiement::PointsFidelite->value)
            ->sum('montant');

        $totalAttendu = $session->solde_ouverture + $totalLiquide;

        $session->update([
            'solde_fermeture_reel' => $validated['solde_fermeture_reel'],
            'total_attendu' => $totalAttendu,
            'statut' => 'fermee',
            'closed_at' => now(),
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Session clôturée avec succès.',
            'data' => $session
        ]);
    }
}
