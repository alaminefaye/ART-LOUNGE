<?php

namespace App\Services;

use App\Models\Client;
use App\Models\Commande;
use App\Models\FidelitySetting;
use App\Models\Paiement;
use Illuminate\Support\Facades\DB;

class FidelityService
{
    /**
     * Créditer les points au client après un paiement "argent réel" (hors points)
     */
    public function crediterPointsPourPaiement(Commande $commande, float $montantFcfaReel): void
    {
        if ($montantFcfaReel <= 0) {
            return;
        }
        $client = $commande->client;
        if (!$client) {
            return;
        }
        $settings = FidelitySetting::get();
        $points = $settings->pointsPourMontant($montantFcfaReel);
        if ($points <= 0) {
            return;
        }
        $client->ajouterPoints(
            $points,
            'Commande #' . $commande->id . ' - ' . number_format($montantFcfaReel, 0, '', ' ') . ' FCFA',
            $commande->id
        );
    }

    /**
     * Débiter les points du client (paiement en points)
     */
    public function debiterPoints(Client $client, int $points, string $description, ?int $commandeId = null): void
    {
        $client->retirerPoints($points, $description, $commandeId);
    }

    /**
     * Montant total déjà payé pour cette commande (somme des paiements validés)
     */
    public function montantDejaPaye(Commande $commande): float
    {
        return (float) $commande->paiements()
            ->where('statut', \App\Enums\StatutPaiement::Valide)
            ->sum('montant');
    }

    /**
     * Montant payé en "argent réel" (hors points) pour une commande
     */
    public function montantPayeReel(Commande $commande): float
    {
        return (float) $commande->paiements()
            ->where('statut', \App\Enums\StatutPaiement::Valide)
            ->where('moyen_paiement', '!=', \App\Enums\MoyenPaiement::PointsFidelite)
            ->sum('montant');
    }
}
