<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\CaisseSession;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class CaisseSessionController extends Controller
{
    public function index()
    {
        $session_active = CaisseSession::where('user_id', Auth::id())
            ->where('statut', 'ouverte')
            ->first();

        $historique = CaisseSession::where('user_id', Auth::id())
            ->where('statut', 'fermee')
            ->orderByDesc('closed_at')
            ->paginate(10);

        return view('caisse.sessions.index', [
            'session_active' => $session_active,
            'historique' => $historique
        ]);
    }

    public function ouvrir(Request $request)
    {
        $request->validate([
            'solde_ouverture' => 'required|numeric|min:0',
        ]);

        // Vérifier si une session est déjà ouverte
        $session_existante = CaisseSession::where('user_id', Auth::id())
            ->where('statut', 'ouverte')
            ->exists();

        if ($session_existante) {
            return back()->with('error', 'Vous avez déjà une session de caisse ouverte.');
        }

        CaisseSession::create([
            'user_id' => Auth::id(),
            'solde_ouverture' => $request->solde_ouverture,
            'statut' => 'ouverte',
            'opened_at' => now(),
        ]);

        return redirect()->route('caisse.sessions.index')->with('success', 'Session de caisse ouverte avec succès.');
    }

    public function bilan()
    {
        $session = CaisseSession::where('user_id', Auth::id())
            ->where('statut', 'ouverte')
            ->firstOrFail();

        $paiements = $session->paiements()->where('statut', 'valide')->get();
        
        $details = [
            'total_especes' => $paiements->where('moyen_paiement.value', 'especes')->sum('montant'),
            'total_wave' => $paiements->where('moyen_paiement.value', 'wave')->sum('montant'),
            'total_orange_money' => $paiements->where('moyen_paiement.value', 'orange_money')->sum('montant'),
            'total_carte' => $paiements->where('moyen_paiement.value', 'carte_bancaire')->sum('montant'),
            'total_points' => $paiements->where('moyen_paiement.value', 'points_fidelite')->sum('montant'),
            'total_ventes' => $paiements->sum('montant'),
        ];

        return view('caisse.sessions.bilan', compact('session', 'details'));
    }

    public function fermer(Request $request)
    {
        $request->validate([
            'solde_fermeture_reel' => 'required|numeric|min:0',
        ]);

        $session = CaisseSession::where('user_id', Auth::id())
            ->where('statut', 'ouverte')
            ->firstOrFail();

        $total_ventes_vrai = $session->paiements()->where('statut', 'valide')->sum('montant');
        $total_attendu = $session->solde_ouverture + $total_ventes_vrai;

        $session->update([
            'solde_fermeture_reel' => $request->solde_fermeture_reel,
            'total_attendu' => $total_attendu,
            'statut' => 'fermee',
            'closed_at' => now(),
        ]);

        return redirect()->route('caisse.sessions.index')->with('success', 'Session de caisse clôturée avec succès.');
    }
}
