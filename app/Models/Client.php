<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Client extends Model
{
    protected $fillable = [
        'user_id',
        'nom',
        'prenom',
        'telephone',
        'email',
        'date_naissance',
        'adresse',
        'points_fidelite',
        'total_depenses',
        'nombre_visites',
        'date_derniere_visite',
        'date_inscription',
        'actif',
    ];

    protected $casts = [
        'date_naissance' => 'date',
        'date_derniere_visite' => 'date',
        'date_inscription' => 'date',
        'points_fidelite' => 'integer',
        'total_depenses' => 'decimal:2',
        'nombre_visites' => 'integer',
        'actif' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Historique des points
     */
    public function historiquePoints(): HasMany
    {
        return $this->hasMany(HistoriquePoint::class);
    }

    /**
     * Ajouter des points
     */
    public function ajouterPoints(int $points, string $description, ?int $commandeId = null): void
    {
        $this->points_fidelite += $points;
        $this->save();

        $this->historiquePoints()->create([
            'points' => $points,
            'type' => 'gain',
            'description' => $description,
            'commande_id' => $commandeId,
        ]);
    }

    /**
     * Retirer des points
     */
    public function retirerPoints(int $points, string $description, ?int $commandeId = null): void
    {
        $this->points_fidelite = max(0, $this->points_fidelite - $points);
        $this->save();

        $this->historiquePoints()->create([
            'points' => -$points,
            'type' => 'depense',
            'description' => $description,
            'commande_id' => $commandeId,
        ]);
    }

    /**
     * Enregistrer une visite (mise à jour stats + points selon paramètres fidélité)
     */
    public function enregistrerVisite(float $montant, ?int $commandeId = null): void
    {
        $this->nombre_visites++;
        $this->total_depenses += $montant;
        $this->date_derniere_visite = now();
        $this->save();

        $settings = \App\Models\FidelitySetting::get();
        $pointsGagnes = $settings->pointsPourMontant($montant);
        if ($pointsGagnes > 0) {
            $this->ajouterPoints(
                $pointsGagnes,
                'Achat ' . number_format($montant, 0, '', ' ') . ' FCFA',
                $commandeId
            );
        }
    }

    /**
     * Scope pour les clients actifs
     */
    public function scopeActifs($query)
    {
        return $query->where('actif', true);
    }

    /**
     * Obtenir le nom complet
     */
    public function getNomCompletAttribute(): string
    {
        return "{$this->prenom} {$this->nom}";
    }
}

