<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Serveur extends Model
{
    use HasFactory;

    protected $fillable = [
        'nom',
        'prenom',
        'telephone',
        'actif',
    ];

    protected $casts = [
        'actif' => 'boolean',
    ];

    public function commandes()
    {
        return $this->hasMany(Commande::class);
    }
}
