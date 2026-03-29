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
        $totalLiquide = $totaux->where('moyen_paiement', '!=', MoyenPaiement::PointsFidelite->value)->sum('total');
        
        // Détails des points de fidélité utilisés
        $pointsDetails = Paiement::where('caisse_session_id', $session->id)
            ->where('statut', StatutPaiement::Valide->value)
            ->where('moyen_paiement', MoyenPaiement::PointsFidelite->value)
            ->with(['client:id,nom,prenom', 'commande.table:id,numero'])
            ->select('id', 'client_id', 'montant', 'points_utilises', 'commande_id')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'session' => $session,
                'repartition' => $totaux,
                'total_ventes' => $totalVentes,
                'total_liquide' => $totalLiquide,
                'total_attendu_caisse' => $session->solde_ouverture + $totalLiquide,
                'points_details' => $pointsDetails
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
