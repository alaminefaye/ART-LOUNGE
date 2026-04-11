<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Enums\OrderStatus;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StatsController extends Controller
{
    public function produits(Request $request)
    {
        $days = (int) $request->input('periode', 30);
        if (! in_array($days, [7, 30, 90, 365], true)) {
            $days = 30;
        }

        $start = now()->subDays($days)->startOfDay();
        $excluded = [OrderStatus::Annulee->value];

        // ── Top 15 produits par quantité ─────────────────────────────────────
        $topParQuantite = DB::table('commande_produit')
            ->join('commandes', 'commandes.id', '=', 'commande_produit.commande_id')
            ->join('produits',  'produits.id',  '=', 'commande_produit.produit_id')
            ->leftJoin('categories', 'categories.id', '=', 'produits.categorie_id')
            ->where('commandes.created_at', '>=', $start)
            ->whereNotIn('commandes.statut', $excluded)
            ->select(
                'produits.id',
                'produits.nom',
                DB::raw('COALESCE(categories.nom, \'Sans catégorie\') as categorie'),
                DB::raw('SUM(commande_produit.quantite) as quantite'),
                DB::raw('SUM(commande_produit.quantite * produits.prix) as revenus')
            )
            ->groupBy('produits.id', 'produits.nom', 'categories.nom')
            ->orderByDesc('quantite')
            ->limit(15)
            ->get();

        // ── Top 10 produits par revenus ───────────────────────────────────────
        $topParRevenu = DB::table('commande_produit')
            ->join('commandes', 'commandes.id', '=', 'commande_produit.commande_id')
            ->join('produits',  'produits.id',  '=', 'commande_produit.produit_id')
            ->where('commandes.created_at', '>=', $start)
            ->whereNotIn('commandes.statut', $excluded)
            ->select(
                'produits.nom',
                DB::raw('SUM(commande_produit.quantite) as quantite'),
                DB::raw('SUM(commande_produit.quantite * produits.prix) as revenus')
            )
            ->groupBy('produits.id', 'produits.nom')
            ->orderByDesc('revenus')
            ->limit(10)
            ->get();

        // ── Répartition par catégorie ─────────────────────────────────────────
        $parCategorie = DB::table('commande_produit')
            ->join('commandes',   'commandes.id',   '=', 'commande_produit.commande_id')
            ->join('produits',    'produits.id',    '=', 'commande_produit.produit_id')
            ->leftJoin('categories', 'categories.id', '=', 'produits.categorie_id')
            ->where('commandes.created_at', '>=', $start)
            ->whereNotIn('commandes.statut', $excluded)
            ->select(
                DB::raw('COALESCE(categories.nom, \'Sans catégorie\') as categorie'),
                DB::raw('SUM(commande_produit.quantite) as quantite'),
                DB::raw('SUM(commande_produit.quantite * produits.prix) as revenus')
            )
            ->groupBy('categories.id', 'categories.nom')
            ->orderByDesc('revenus')
            ->get();

        // ── Ventes par heure ──────────────────────────────────────────────────
        $parHeure = DB::table('commande_produit')
            ->join('commandes', 'commandes.id', '=', 'commande_produit.commande_id')
            ->where('commandes.created_at', '>=', $start)
            ->whereNotIn('commandes.statut', $excluded)
            ->selectRaw('HOUR(commandes.created_at) as heure, SUM(commande_produit.quantite) as total')
            ->groupBy(DB::raw('HOUR(commandes.created_at)'))
            ->orderBy('heure')
            ->get()
            ->keyBy('heure');

        $labelsHeures = [];
        $dataHeures   = [];
        for ($h = 0; $h < 24; $h++) {
            $labelsHeures[] = sprintf('%02dh', $h);
            $dataHeures[]   = (int) ($parHeure->get($h)?->total ?? 0);
        }

        // ── KPIs ──────────────────────────────────────────────────────────────
        $totalArticles  = (int) $topParQuantite->sum('quantite');
        $totalRevenus   = (float) $topParQuantite->sum('revenus');
        $nbProduits     = DB::table('commande_produit')
            ->join('commandes', 'commandes.id', '=', 'commande_produit.commande_id')
            ->where('commandes.created_at', '>=', $start)
            ->whereNotIn('commandes.statut', $excluded)
            ->distinct('commande_produit.produit_id')
            ->count('commande_produit.produit_id');

        // ── Tableau complet de tous les produits ──────────────────────────────
        $tousProduits = DB::table('commande_produit')
            ->join('commandes',  'commandes.id',  '=', 'commande_produit.commande_id')
            ->join('produits',   'produits.id',   '=', 'commande_produit.produit_id')
            ->leftJoin('categories', 'categories.id', '=', 'produits.categorie_id')
            ->where('commandes.created_at', '>=', $start)
            ->whereNotIn('commandes.statut', $excluded)
            ->select(
                'produits.nom',
                DB::raw('COALESCE(categories.nom, \'Sans catégorie\') as categorie'),
                DB::raw('SUM(commande_produit.quantite) as quantite'),
                DB::raw('SUM(commande_produit.quantite * produits.prix) as revenus')
            )
            ->groupBy('produits.id', 'produits.nom', 'categories.nom')
            ->orderByDesc('quantite')
            ->get();

        $grandTotalQte = max(1, $tousProduits->sum('quantite'));

        return view('stats.produits', compact(
            'days',
            'start',
            'topParQuantite',
            'topParRevenu',
            'parCategorie',
            'labelsHeures',
            'dataHeures',
            'totalArticles',
            'totalRevenus',
            'nbProduits',
            'tousProduits',
            'grandTotalQte'
        ));
    }
}
