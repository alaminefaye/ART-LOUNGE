<?php

namespace App\Http\Controllers;

use App\Enums\MoyenPaiement;
use App\Enums\OrderStatus;
use App\Enums\StatutPaiement;
use App\Models\Commande;
use App\Models\Paiement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $days = (int) $request->get('periode', 30);
        if (! in_array($days, [7, 30, 90], true)) {
            $days = 30;
        }

        $start = now()->subDays($days)->startOfDay();

        $caTotal = (float) Paiement::query()
            ->where('statut', StatutPaiement::Valide)
            ->where('created_at', '>=', $start)
            ->sum('montant');

        $nbPaiements = Paiement::query()
            ->where('statut', StatutPaiement::Valide)
            ->where('created_at', '>=', $start)
            ->count();

        $caMoyenParPaiement = $nbPaiements > 0 ? $caTotal / $nbPaiements : 0;

        // CA par jour (graphique ligne)
        $dateExpr = DB::connection()->getDriverName() === 'sqlite'
            ? "date(created_at)"
            : 'DATE(created_at)';
        $rowsCaJour = Paiement::query()
            ->where('statut', StatutPaiement::Valide)
            ->where('created_at', '>=', $start)
            ->selectRaw("{$dateExpr} as jour")
            ->selectRaw('SUM(montant) as total')
            ->groupBy(DB::raw($dateExpr))
            ->orderBy('jour')
            ->get()
            ->keyBy('jour');

        $labelsJours = [];
        $dataCaJour = [];
        for ($i = $days - 1; $i >= 0; $i--) {
            $d = now()->subDays($i)->format('Y-m-d');
            $labelsJours[] = now()->subDays($i)->format('d/m');
            $row = $rowsCaJour->get($d);
            $dataCaJour[] = $row ? (float) $row->total : 0.0;
        }

        // Répartition par moyen de paiement (donut)
        $parMoyen = Paiement::query()
            ->where('statut', StatutPaiement::Valide)
            ->where('created_at', '>=', $start)
            ->selectRaw('moyen_paiement, SUM(montant) as total')
            ->groupBy('moyen_paiement')
            ->get();

        $labelsMoyen = [];
        $dataMoyen = [];
        $couleursMoyen = [];
        $palette = ['#696cff', '#03c3ec', '#71dd37', '#ffab00', '#ff3e1d', '#8592a3'];
        $i = 0;
        foreach ($parMoyen as $row) {
            $enum = $row->moyen_paiement;
            if ($enum instanceof MoyenPaiement) {
                $labelsMoyen[] = $this->labelMoyenPaiement($enum);
            } else {
                try {
                    $labelsMoyen[] = $this->labelMoyenPaiement(MoyenPaiement::from((string) $row->moyen_paiement));
                } catch (\ValueError) {
                    $labelsMoyen[] = (string) $row->moyen_paiement;
                }
            }
            $dataMoyen[] = (float) $row->total;
            $couleursMoyen[] = $palette[$i % count($palette)];
            $i++;
        }

        // Commandes par statut (période)
        $parStatut = DB::table('commandes')
            ->where('created_at', '>=', $start)
            ->select('statut', DB::raw('COUNT(*) as total'))
            ->groupBy('statut')
            ->get();

        $labelsStatut = [];
        $dataStatut = [];
        foreach ($parStatut as $row) {
            try {
                $labelsStatut[] = $this->labelStatutCommande(OrderStatus::from($row->statut));
            } catch (\ValueError) {
                $labelsStatut[] = (string) $row->statut;
            }
            $dataStatut[] = (int) $row->total;
        }

        // Top produits (quantités vendues sur la période)
        $topProduits = Commande::query()
            ->where('commandes.created_at', '>=', $start)
            ->join('commande_produit', 'commandes.id', '=', 'commande_produit.commande_id')
            ->join('produits', 'commande_produit.produit_id', '=', 'produits.id')
            ->selectRaw('produits.nom as nom, SUM(commande_produit.quantite) as quantite')
            ->groupBy('produits.id', 'produits.nom')
            ->orderByDesc('quantite')
            ->limit(10)
            ->get();

        // Comparaison mois en cours vs mois précédent (CA)
        $debutMois = now()->startOfMonth();
        $finMois = now()->endOfMonth();
        $debutMoisPrec = now()->subMonth()->startOfMonth();
        $finMoisPrec = now()->subMonth()->endOfMonth();

        $caMoisEnCours = (float) Paiement::query()
            ->where('statut', StatutPaiement::Valide)
            ->whereBetween('created_at', [$debutMois, $finMois])
            ->sum('montant');

        $caMoisPrecedent = (float) Paiement::query()
            ->where('statut', StatutPaiement::Valide)
            ->whereBetween('created_at', [$debutMoisPrec, $finMoisPrec])
            ->sum('montant');

        $evolutionMoisPct = $caMoisPrecedent > 0
            ? (($caMoisEnCours - $caMoisPrecedent) / $caMoisPrecedent) * 100
            : null;

        // Performance par personnel (CA et nombre de transactions)
        $performancePersonnel = Paiement::query()
            ->where('paiements.statut', StatutPaiement::Valide)
            ->where('paiements.created_at', '>=', $start)
            ->join('users', 'paiements.user_id', '=', 'users.id')
            ->select('users.name', DB::raw('COUNT(*) as nb_transactions'), DB::raw('SUM(montant) as total_ca'))
            ->groupBy('users.id', 'users.name')
            ->orderByDesc('total_ca')
            ->get();

        return view('rapport.index', compact(
            'days',
            'start',
            'caTotal',
            'nbPaiements',
            'caMoyenParPaiement',
            'labelsJours',
            'dataCaJour',
            'labelsMoyen',
            'dataMoyen',
            'couleursMoyen',
            'labelsStatut',
            'dataStatut',
            'topProduits',
            'caMoisEnCours',
            'caMoisPrecedent',
            'evolutionMoisPct',
            'performancePersonnel'
        ));
    }

    private function labelMoyenPaiement(MoyenPaiement $m): string
    {
        return match ($m) {
            MoyenPaiement::Especes => 'Espèces',
            MoyenPaiement::Wave => 'Wave',
            MoyenPaiement::OrangeMoney => 'Orange Money',
            MoyenPaiement::CarteBancaire => 'Carte bancaire',
            MoyenPaiement::PointsFidelite => 'Points fidélité',
        };
    }

    private function labelStatutCommande(OrderStatus $s): string
    {
        return match ($s) {
            OrderStatus::Attente => 'En attente',
            OrderStatus::Preparation => 'En préparation',
            OrderStatus::Servie => 'Servie',
            OrderStatus::Terminee => 'Terminée',
            OrderStatus::Annulee => 'Annulée',
        };
    }
}
