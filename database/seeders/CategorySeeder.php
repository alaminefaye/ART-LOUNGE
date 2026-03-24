<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

/**
 * Menu Dolce Vita Palace — catégories (ordre d’affichage).
 */
class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['nom' => 'Entrées froides', 'description' => 'Menu Dolce Vita Palace — entrées froides', 'ordre' => 1, 'actif' => true],
            ['nom' => 'Entrées chaudes', 'description' => 'Menu Dolce Vita Palace — entrées chaudes', 'ordre' => 2, 'actif' => true],
            ['nom' => 'Poissons & fruits de mer', 'description' => 'Menu Dolce Vita Palace', 'ordre' => 3, 'actif' => true],
            ['nom' => 'Viandes', 'description' => 'Menu Dolce Vita Palace', 'ordre' => 4, 'actif' => true],
            ['nom' => 'Volailles & gibiers', 'description' => 'Menu Dolce Vita Palace', 'ordre' => 5, 'actif' => true],
            ['nom' => 'Brochettes', 'description' => 'Menu Dolce Vita Palace', 'ordre' => 6, 'actif' => true],
            ['nom' => 'Plats africains', 'description' => 'Menu Dolce Vita Palace', 'ordre' => 7, 'actif' => true],
            ['nom' => 'Pâtes', 'description' => 'Menu Dolce Vita Palace', 'ordre' => 8, 'actif' => true],
            ['nom' => 'Fast food', 'description' => 'Menu Dolce Vita Palace — sandwiches, burgers, pizzas', 'ordre' => 9, 'actif' => true],
            ['nom' => 'Garnitures', 'description' => 'Menu Dolce Vita Palace', 'ordre' => 10, 'actif' => true],
            ['nom' => 'Desserts', 'description' => 'Menu Dolce Vita Palace', 'ordre' => 11, 'actif' => true],
        ];

        foreach ($categories as $category) {
            Category::updateOrCreate(
                ['nom' => $category['nom']],
                $category
            );
        }

        $this->command->info('✓ '.count($categories).' catégories Dolce Vita Palace');
    }
}
