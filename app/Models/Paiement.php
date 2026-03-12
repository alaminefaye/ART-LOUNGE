<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Paiement extends Model
{
    use HasFactory;

    protected $fillable = [
        'commande_id',
        'user_id',
        'client_id',
        'montant',
        'moyen_paiement',
        'statut',
        'transaction_id',
        'montant_recu',
        'monnaie_rendue',
        'notes',
        'points_utilises',
    ];

    protected $casts = [
        'moyen_paiement' => \App\Enums\MoyenPaiement::class,
        'statut' => \App\Enums\StatutPaiement::class,
        'montant' => 'decimal:2',
        'montant_recu' => 'decimal:2',
        'monnaie_rendue' => 'decimal:2',
        'points_utilises' => 'integer',
    ];

    public function commande(): BelongsTo
    {
        return $this->belongsTo(Commande::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function client(): BelongsTo
    {
        return $this->belongsTo(Client::class);
    }

    public function facture(): HasOne
    {
        return $this->hasOne(Facture::class);
    }

    // Helper methods
    public function isValide(): bool
    {
        return $this->statut === \App\Enums\StatutPaiement::Valide;
    }

    public function valider(): void
    {
        $this->statut = \App\Enums\StatutPaiement::Valide;
        $this->save();
    }

    public function echouer(): void
    {
        $this->statut = \App\Enums\StatutPaiement::Echoue;
        $this->save();
    }

    public function calculerMonnaie(): void
    {
        if ($this->moyen_paiement === \App\Enums\MoyenPaiement::Especes && $this->montant_recu) {
            $this->monnaie_rendue = $this->montant_recu - $this->montant;
            $this->save();
        }
    }
}
