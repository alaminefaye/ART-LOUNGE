<?php

namespace Database\Seeders;

/**
 * Source unique : MENU DOLCE VITA PALACE (catégories + liste des noms autorisés).
 */
final class DolceVitaMenu
{
    /** @return list<string> */
    public static function categoryNames(): array
    {
        return [
            'Entrées froides',
            'Entrées chaudes',
            'Poissons & fruits de mer',
            'Viandes',
            'Volailles & gibiers',
            'Brochettes',
            'Plats africains',
            'Pâtes',
            'Fast food',
            'Garnitures',
            'Desserts',
            'MENU BOISSONS — Cocktails alcoolisés',
            'MENU BOISSONS — Cocktails sans alcool',
        ];
    }
}
