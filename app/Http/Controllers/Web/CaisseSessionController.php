<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\CaisseSession;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;

class CaisseSessionController extends Controller
{
    public function index(Request $request)
    {
        $canViewAll = Gate::any(['manage_sessions', 'view_reports']);
        $perPage = (int) $request->input('per_page', 10);
        if (! in_array($perPage, [10, 25, 50], true)) {
            $perPage = 10;
        }

        $cashiers = collect();
        if ($canViewAll) {
            $cashierIds = CaisseSession::query()
                ->where('statut', 'fermee')
                ->distinct()
                ->pluck('user_id');

            $cashiers = User::query()
                ->whereIn('id', $cashierIds)
                ->orderBy('name')
                ->get(['id', 'name', 'email']);
        }

        $session_active = CaisseSession::where('user_id', Auth::id())
            ->where('statut', 'ouverte')
            ->first();

        $historiqueQuery = CaisseSession::query()
            ->where('statut', 'fermee')
            ->with('user')
            ->orderByDesc('closed_at');

        if (! $canViewAll) {
            $historiqueQuery->where('user_id', Auth::id());
        }

        if ($request->filled('date_from')) {
            $historiqueQuery->whereDate('opened_at', '>=', $request->input('date_from'));
        }
        if ($request->filled('date_to')) {
            $historiqueQuery->whereDate('opened_at', '<=', $request->input('date_to'));
        }

        if ($canViewAll && $request->filled('cashier_id')) {
            $cashierId = (int) $request->input('cashier_id');
            if ($cashierId > 0) {
                $historiqueQuery->where('user_id', $cashierId);
            }
        }

        $historique = $historiqueQuery->paginate($perPage)->withQueryString();

        return view('caisse.sessions.index', [
            'session_active' => $session_active,
            'historique' => $historique,
            'perPage' => $perPage,
            'canViewAll' => $canViewAll,
            'cashiers' => $cashiers,
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

        $details = $this->totauxPaiementsSession($session);

        return view('caisse.sessions.bilan', compact('session', 'details'));
    }

    /**
     * Rapport imprimable d'une session clôturée (historique).
     */
    public function rapport(CaisseSession $session)
    {
        $canViewAll = Gate::any(['manage_sessions', 'view_reports']);

        if ($session->user_id !== Auth::id() && ! $canViewAll) {
            abort(403);
        }

        if ($session->statut !== 'fermee') {
            return redirect()
                ->route('caisse.sessions.index')
                ->with('error', 'Le rapport n\'est disponible que pour les sessions clôturées.');
        }

        $session->load('user');
        $details = $this->totauxPaiementsSession($session);
        $ecart = (float) $session->solde_fermeture_reel - (float) $session->total_attendu;

        return view('caisse.sessions.rapport', compact('session', 'details', 'ecart'));
    }

    /**
     * @return array{total_especes: float|int, total_wave: float|int, total_orange_money: float|int, total_carte: float|int, total_points: float|int, total_ventes: float|int}
     */
    private function totauxPaiementsSession(CaisseSession $session): array
    {
        $paiements = $session->paiements()
            ->where('statut', 'valide')
            ->with(['client:id,nom,prenom', 'commande.table:id,numero'])
            ->get();

        return [
            'total_especes' => $paiements->where('moyen_paiement.value', 'especes')->sum('montant'),
            'total_wave' => $paiements->where('moyen_paiement.value', 'wave')->sum('montant'),
            'total_orange_money' => $paiements->where('moyen_paiement.value', 'orange_money')->sum('montant'),
            'total_carte' => $paiements->where('moyen_paiement.value', 'carte_bancaire')->sum('montant'),
            'total_points' => $paiements->where('moyen_paiement.value', 'points_fidelite')->sum('montant'),
            'total_ventes' => $paiements->sum('montant'),
            'points_details' => $paiements->where('moyen_paiement.value', 'points_fidelite'),
        ];
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
