<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FidelitySetting extends Model
{
    protected $table = 'fidelity_settings';

    protected $fillable = [
        'fcfa_pour_1_point',
        'valeur_fcfa_1_point',
        'actif',
    ];

    protected $casts = [
        'fcfa_pour_1_point' => 'integer',
        'valeur_fcfa_1_point' => 'decimal:2',
        'actif' => 'boolean',
    ];

    /**
     * Paramètres globaux (une seule ligne en base)
     */
    public static function get(): self
    {
        $row = self::first();
        if (!$row) {
            $row = self::create([
                'fcfa_pour_1_point' => 1000,
                'valeur_fcfa_1_point' => 100,
                'actif' => true,
            ]);
        }
        return $row;
    }

    /**
     * Nombre de points gagnés pour un montant dépensé (FCFA)
     */
    public function pointsPourMontant(float $montantFcfa): int
    {
        if (!$this->actif || $this->fcfa_pour_1_point <= 0) {
            return 0;
        }
        return (int) floor($montantFcfa / $this->fcfa_pour_1_point);
    }

    /**
     * Réduction FCFA pour un nombre de points
     */
    public function fcfaPourPoints(int $points): float
    {
        if (!$this->actif || $this->valeur_fcfa_1_point <= 0) {
            return 0.0;
        }
        return (float) ($points * $this->valeur_fcfa_1_point);
    }

    /**
     * Nombre de points nécessaires pour une réduction FCFA (plafonné au max utilisable)
     */
    public function pointsPourReduction(float $montantFcfa): int
    {
        if (!$this->actif || $this->valeur_fcfa_1_point <= 0) {
            return 0;
        }
        return (int) ceil($montantFcfa / $this->valeur_fcfa_1_point);
    }
}
