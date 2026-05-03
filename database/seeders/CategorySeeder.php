<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

/**
 * Menu ART MOMENTS — uniquement ces catégories (aucune autre).
 */
class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $names = ArtMomentsMenu::categoryNames();

        $categories = [];
        foreach ($names as $index => $nom) {
            $categories[] = [
                'nom' => $nom,
                'description' => 'Menu ART MOMENTS',
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

        $this->command->info('✓ '.count($categories).' catégories Menu ART MOMENTS');
    }
}
