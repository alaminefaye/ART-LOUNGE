<?php

namespace App\Enums;

enum MoyenPaiement: string
{
    case Especes = 'especes';
    case Wave = 'wave';
    case OrangeMoney = 'orange_money';
    case CarteBancaire = 'carte_bancaire';
    case PointsFidelite = 'points_fidelite';

    public function displayName(): string
    {
        return match($this) {
            self::Especes => 'Espèces',
            self::Wave => 'Wave',
            self::OrangeMoney => 'Orange Money',
            self::CarteBancaire => 'Carte Bancaire',
            self::PointsFidelite => 'Points de Fidélité',
        };
    }
}

