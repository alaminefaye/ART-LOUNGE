<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CaisseSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'solde_ouverture',
        'solde_fermeture_reel',
        'total_attendu',
        'statut',
        'opened_at',
        'closed_at',
    ];

    protected $casts = [
        'opened_at' => 'datetime',
        'closed_at' => 'datetime',
        'solde_ouverture' => 'decimal:2',
        'solde_fermeture_reel' => 'decimal:2',
        'total_attendu' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function paiements(): HasMany
    {
        return $this->hasMany(Paiement::class);
    }

    public function scopeOuverte($query)
    {
        return $query->where('statut', 'ouverte');
    }
}
