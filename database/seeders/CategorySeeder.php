<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

/**
 * MENU DOLCE VITA PALACE — uniquement ces catégories (aucune autre).
 */
class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $names = DolceVitaMenu::categoryNames();

        $categories = [];
        foreach ($names as $index => $nom) {
            $categories[] = [
                'nom' => $nom,
                'description' => 'Menu Dolce Vita Palace',
                'ordre' => $index + 1,
                'actif' => true,
            ];
        }

        foreach ($categories as $category) {
            Category::updateOrCreate(
                ['nom' => $category['nom']],
                $category
            );
        }

        $this->command->info('✓ '.count($categories).' catégories Menu Dolce Vita Palace');
    }
}
