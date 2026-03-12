<?php

namespace App\Enums;

enum MoyenPaiement: string
{
    case Especes = 'especes';
    case Wave = 'wave';
    case OrangeMoney = 'orange_money';
    case CarteBancaire = 'carte_bancaire';
    case PointsFidelite = 'points_fidelite';
}

