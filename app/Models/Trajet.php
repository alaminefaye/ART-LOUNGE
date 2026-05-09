<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Trajet extends Model
{
    use HasFactory;

    protected $fillable = [
        'depart',
        'destination',
        'heure_depart',
        'actif',
    ];

    protected $casts = [
        'actif' => 'boolean',
    ];

    public function commandes(): HasMany
    {
        return $this->hasMany(Commande::class);
    }
}
