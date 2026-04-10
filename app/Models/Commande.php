<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Enums\OrderStatus;

class Commande extends Model
{
    use HasFactory;
    // Statuts
    const STATUT_ATTENTE = 'attente';
    const STATUT_PREPARATION = 'preparation';
    const STATUT_SERVIE = 'servie';
    const STATUT_TERMINEE = 'terminee';
    const STATUT_ANNULEE = 'annulee';

    protected $fillable = [
        'table_id',
        'user_id',
        'client_id',
        'serveur_id',
        'statut',
        'montant_total',
        'notes',
    ];

    protected $casts = [
        'statut' => OrderStatus::class,
        'table_id' => 'integer',
        'user_id' => 'integer',
        'serveur_id' => 'integer',
        'montant_total' => 'decimal:2',
    ];

    /**
     * Une commande appartient à une table
     */
    public function table(): BelongsTo
    {
        return $this->belongsTo(Table::class);
    }

    /**
     * Une commande est créée par un utilisateur (serveur/caissier)
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Serveur qui s'occupe de la table (optionnel)
     */
    public function serveur(): BelongsTo
    {
        return $this->belongsTo(Serveur::class);
    }

    /**
     * Client associé (optionnel, pour fidélité)
     */
    public function client(): BelongsTo
    {
        return $this->belongsTo(Client::class);
    }

    /**
     * Une commande contient plusieurs produits
     */
    public function produits(): BelongsToMany
    {
        return $this->belongsToMany(Product::class, 'commande_produit', 'commande_id', 'produit_id')
            ->withPivot('quantite', 'prix_unitaire', 'notes', 'statut', 'servi')
            ->withTimestamps();
    }

    /**
     * Alias pour products (pour compatibilité avec PaiementController)
     */
    public function products(): BelongsToMany
    {
        return $this->produits();
    }

    /**
     * Une commande peut avoir plusieurs paiements
     */
    public function paiements(): HasMany
    {
        return $this->hasMany(Paiement::class);
    }

    /**
     * Une commande peut avoir une facture
     */
    public function facture(): \Illuminate\Database\Eloquent\Relations\HasOneThrough
    {
        return $this->hasOneThrough(Facture::class, Paiement::class);
    }

    public function avis(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Avis::class);
    }

    /**
     * Obtenir les statuts disponibles
     */
    public static function getStatuts(): array
    {
        return [
            self::STATUT_ATTENTE => 'En attente',
            self::STATUT_PREPARATION => 'En préparation',
            self::STATUT_SERVIE => 'Servie',
            self::STATUT_TERMINEE => 'Terminée',
            self::STATUT_ANNULEE => 'Annulée',
        ];
    }

    /**
     * Obtenir le nom affiché du statut
     */
    public function getStatutDisplayAttribute(): string
    {
        // Si statut est un enum, utiliser sa valeur
        $statutValue = $this->statut instanceof OrderStatus 
            ? $this->statut->value 
            : $this->statut;
        
        return self::getStatuts()[$statutValue] ?? (string) $statutValue;
    }

    /**
     * Changer le statut de la commande
     */
    public function changerStatut(string $nouveauStatut): bool
    {
        if (!in_array($nouveauStatut, array_keys(self::getStatuts()))) {
            return false;
        }

        $this->statut = $nouveauStatut;
        return $this->save();
    }

    /**
     * Ajouter un produit à la commande
     */
    public function ajouterProduit(Product $produit, int $quantite = 1, ?string $notes = null): void
    {
        $this->produits()->attach($produit->id, [
            'quantite' => $quantite,
            'prix_unitaire' => $produit->prix,
            'notes' => $notes,
            'statut' => 'brouillon',
        ]);

        $this->calculerMontantTotal();
    }

    /**
     * Mettre à jour la quantité d'un produit
     */
    public function updateProduitQuantite(int $produitId, int $quantite): void
    {
        if ($quantite <= 0) {
            $this->produits()->detach($produitId);
        } else {
            $this->produits()->updateExistingPivot($produitId, [
                'quantite' => $quantite,
            ]);
        }

        $this->calculerMontantTotal();
    }

    /**
     * Retirer un produit de la commande
     */
    public function retirerProduit(int $produitId): void
    {
        $this->produits()->detach($produitId);
        $this->calculerMontantTotal();
    }

    /**
     * Calculer le montant total de la commande
     */
    public function calculerMontantTotal(): void
    {
        $produitsTotal = \Illuminate\Support\Facades\DB::table('commande_produit')
            ->where('commande_id', $this->id)
            ->sum(\Illuminate\Support\Facades\DB::raw('quantite * prix_unitaire'));

        $fraisSalle = $this->getFraisSalle();
            
        $this->update(['montant_total' => $produitsTotal + $fraisSalle]);
    }

    /**
     * Calculer les frais de salle pour les espaces jeux
     */
    public function getFraisSalle(): float
    {
        // Cannot use $this->table here: it resolves to Model::$table (DB table name string), not the table() relation.
        $tableModel = $this->getRelationValue('table');
        if ($tableModel && $tableModel->type === \App\Enums\TableType::EspaceJeux) {
            $dureeHeures = $this->getDureeOccupationHeures();
            return $dureeHeures * (float) $tableModel->prix_par_heure;
        }
        return 0;
    }

    /**
     * Calculer la durée d'occupation en heures (arrondi au supérieur)
     */
    public function getDureeOccupationHeures(): int
    {
        $start = $this->created_at;
        $end = $this->statut === OrderStatus::Terminee ? $this->updated_at : now();
        
        $diffMinutes = $start->diffInMinutes($end);
        
        // Minimum 1 heure, puis arrondi au supérieur pour chaque heure entamée
        return max(1, (int) ceil($diffMinutes / 60));
    }

    /**
     * Vérifier si la commande peut être modifiée
     */
    public function peutEtreModifiee(): bool
    {
        return !in_array($this->statut, [self::STATUT_TERMINEE, self::STATUT_ANNULEE]);
    }

    /**
     * Scope pour filtrer par statut
     */
    public function scopeOfStatut($query, string $statut)
    {
        return $query->where('statut', $statut);
    }

    /**
     * Scope pour filtrer par table
     */
    public function scopeOfTable($query, int $tableId)
    {
        return $query->where('table_id', $tableId);
    }

    /**
     * Scope pour les commandes actives (non terminées/annulées)
     */
    public function scopeActives($query)
    {
        return $query->whereNotIn('statut', [self::STATUT_TERMINEE, self::STATUT_ANNULEE]);
    }

    /**
     * Scope pour les commandes du jour
     */
    public function scopeDuJour($query)
    {
        return $query->whereDate('created_at', today());
    }
}
