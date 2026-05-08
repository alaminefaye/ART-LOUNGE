<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Support\Facades\Storage;

class Product extends Model
{
    protected $table = 'produits';

    protected $fillable = [
        'categorie_id',
        'nom',
        'description',
        'prix',
        'image',
        'disponible',
        'actif',
    ];

    protected $casts = [
        'categorie_id' => 'integer',
        'prix' => 'decimal:2',
        'disponible' => 'boolean',
        'actif' => 'boolean',
    ];

    /**
     * Un produit appartient à une catégorie
     */
    public function categorie(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'categorie_id');
    }

    /**
     * Un produit peut être dans plusieurs commandes
     */
    public function commandes(): BelongsToMany
    {
        return $this->belongsToMany(Commande::class, 'commande_produit', 'produit_id', 'commande_id')
            ->withPivot('quantite', 'prix_unitaire', 'notes')
            ->withTimestamps();
    }

    /**
     * Obtenir l'URL complète de l'image
     */
    public function getImageUrlAttribute(): ?string
    {
        if (!$this->image) {
            return null;
        }

        if (preg_match('#^https?://#i', $this->image)) {
            return $this->image;
        }

        // Si le chemin commence par "public/", on l'enlève
        $path = str_starts_with($this->image, 'public/') 
            ? substr($this->image, 7) // Enlève "public/"
            : $this->image;

        // Si on est dans un contexte API ou JSON, retourner une URL complète
        // Sinon retourner un chemin relatif pour le web
        $request = request();
        if ($request && ($request->is('api/*') || $request->expectsJson())) {
            $path = ltrim($path, '/');

            $configBaseUrl = rtrim((string) config('app.url'), '/');
            $host = $request->getHttpHost();

            $scheme = $request->getScheme();
            $forwardedProto = $request->header('X-Forwarded-Proto');
            if (is_string($forwardedProto) && strtolower($forwardedProto) === 'https') {
                $scheme = 'https';
            }

            $requestBaseUrl = $scheme . '://' . $host;

            $baseUrl = $configBaseUrl;
            $configHost = $configBaseUrl ? parse_url($configBaseUrl, PHP_URL_HOST) : null;
            $configLooksLocal = $configHost === 'localhost' || $configHost === '127.0.0.1' || $configHost === '0.0.0.0';

            if (empty($baseUrl) || $configLooksLocal) {
                $baseUrl = $requestBaseUrl;
            } elseif (!empty($host) && is_string($configHost) && $configHost !== $host && !$configLooksLocal) {
                $baseUrl = $requestBaseUrl;
            }

            return rtrim($baseUrl, '/') . '/storage/' . $path;
        }

        // Retourner un chemin relatif qui fonctionne avec le domaine actuel
        // Le navigateur résoudra automatiquement l'URL complète
        return '/storage/' . ltrim($path, '/');
    }

    /**
     * Scope pour les produits disponibles
     */
    public function scopeDisponibles($query)
    {
        return $query->where('disponible', true);
    }

    /**
     * Scope pour les produits actifs
     */
    public function scopeActifs($query)
    {
        return $query->where('actif', true);
    }

    /**
     * Scope pour filtrer par catégorie
     */
    public function scopeOfCategorie($query, int $categorieId)
    {
        return $query->where('categorie_id', $categorieId);
    }

    /**
     * Vérifier si le produit est disponible
     */
    public function isDisponible(): bool
    {
        return $this->actif && $this->disponible;
    }
}
