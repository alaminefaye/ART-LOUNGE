<?php

namespace Database\Seeders;

/**
 * Source unique : menu ART MOMENTS (catégories + liste des noms autorisés).
 */
final class ArtMomentsMenu
{
    /** @return list<string> */
    public static function categoryNames(): array
    {
        return [
            'Tapas',
            'Entrées',
            'Poissons & fruits de mer',
            'Viandes',
            'Volailles & spécialités',
            'Brochettes',
            'Plats africains',
            'Pâtes',
            'Fast food',
            'Garnitures',
            'Nos sauces',
            'Desserts',
            'MENU BOISSONS — Cocktails alcoolisés',
            'MENU BOISSONS — Cocktails sans alcool',
            'MENU BOISSONS — Cocktails signature (alcoolisés)',
            'MENU BOISSONS — Cocktails signature (sans alcool)',
            'MENU BOISSONS — Shots classiques & tendances',
            'MENU BOISSONS — Shots aromatisés',
            'MENU BOISSONS — Shots signature ART MOMENTS',
            'Champagnes & vins mousseux',
            'Vins rouges',
            'Vins blancs',
            'Vins pétillants',
            'Whiskies',
            'Cognac',
            'Spiritueux divers',
            'Bières',
        ];
    }
}
