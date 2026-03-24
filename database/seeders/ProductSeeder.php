<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Seeder;

/**
 * Menu Dolce Vita Palace — tous les produits et tarifs (FCFA).
 * Pizzas à double tarif : deux lignes produit (formats distincts).
 */
class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $produits = [
            // ——— Entrées froides ———
            ['categorie' => 'Entrées froides', 'nom' => 'Salade de gésiers', 'description' => 'Entrée froide — Menu Dolce Vita Palace', 'prix' => 4000],
            ['categorie' => 'Entrées froides', 'nom' => 'Salade Dolce Vita', 'description' => 'Entrée froide — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées froides', 'nom' => 'Fraîcheur d\'avocat et crevettes', 'description' => 'Entrée froide — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées froides', 'nom' => 'Salade fondante exotique', 'description' => 'Entrée froide — Menu Dolce Vita Palace', 'prix' => 4000],
            ['categorie' => 'Entrées froides', 'nom' => 'Salade César', 'description' => 'Entrée froide — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées froides', 'nom' => 'Salade verte', 'description' => 'Entrée froide — Menu Dolce Vita Palace', 'prix' => 2000],

            // ——— Entrées chaudes ———
            ['categorie' => 'Entrées chaudes', 'nom' => 'Salade de gésiers', 'description' => 'Entrée chaude — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées chaudes', 'nom' => 'Salade de crevettes sautées pili-pili', 'description' => 'Entrée chaude — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées chaudes', 'nom' => 'Salade croustillante de pintade', 'description' => 'Entrée chaude — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées chaudes', 'nom' => 'Salade chicken wings', 'description' => 'Entrée chaude — Menu Dolce Vita Palace', 'prix' => 6000],
            ['categorie' => 'Entrées chaudes', 'nom' => 'Salade ken nuggets', 'description' => 'Entrée chaude — Menu Dolce Vita Palace', 'prix' => 6000],

            // ——— Poissons & fruits de mer ———
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Filet de capitaine aux épinards', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Pavé royal de saumon sauce roquefort', 'description' => 'Menu Dolce Vita Palace', 'prix' => 15000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Pavé de mérou sauce forestière', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Snack de sole marinade Dolce Vita', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Sole frite à l\'ivoirienne (aloco)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Sole meunière purée de patate douce', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Calamars panés aux épices américaines frites', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Sauté de calamars aux épices américaines pommes vapeur', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Snack de gambas tigrées à l\'ail', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Gambas tigrées au beurre d\'agrumes et chorizo', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],

            // ——— Viandes ———
            ['categorie' => 'Viandes', 'nom' => 'Pavé de steak au poivre', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Viandes', 'nom' => 'Mignon de steak rôti', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Viandes', 'nom' => 'Entrecôte royale sauce au poivre', 'description' => 'Menu Dolce Vita Palace', 'prix' => 11000],
            ['categorie' => 'Viandes', 'nom' => 'Côtelettes d\'agneau', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],

            // ——— Volailles & gibiers ———
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Sauté de poulet aux épices thaïlandaises (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Poulet frit au beurre classique (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Poulet au curry (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Choukouya de poulet façon Dolce Vita (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6500],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Snack de pintade à l\'ail (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Sauté de pintade savoureuse (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7500],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Pintade frite au beurre (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7500],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Choukouya de pintade façon Dolce Vita (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Snack de lapin à l\'origan (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Lapin frit à la moutarde à l\'ancienne (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Sauté de lapin aux épices jamaïcaines (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Choukouya de lapin', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Blanquette de poulet aux champignons de Paris', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Volailles & gibiers', 'nom' => 'Magret de canard gratiné', 'description' => 'Menu Dolce Vita Palace', 'prix' => 14000],

            // ——— Brochettes ———
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de mérou', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de gambas', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de bœuf', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de poulet', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes Dolce Vita', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes d\'escargots', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],

            // ——— Plats africains ———
            ['categorie' => 'Plats africains', 'nom' => 'Kedjenou de poulet africain', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6000],
            ['categorie' => 'Plats africains', 'nom' => 'Kedjenou de pintade entière', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Plats africains', 'nom' => 'Kedjenou d\'escargots', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Plats africains', 'nom' => 'Braisé de queue de bœuf', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Plats africains', 'nom' => 'Soupe du pêcheur', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],

            // ——— Pâtes ———
            ['categorie' => 'Pâtes', 'nom' => 'Penne arrabiata', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Pâtes', 'nom' => 'Tagliatelles aux fruits de mer', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Pâtes', 'nom' => 'Spaghetti bolognaise', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6000],
            ['categorie' => 'Pâtes', 'nom' => 'Tagliatelles carbonara', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],

            // ——— Fast food ———
            ['categorie' => 'Fast food', 'nom' => 'Club sandwich', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Fast food', 'nom' => 'Croque-monsieur', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Fast food', 'nom' => 'Croque-madame', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Fast food', 'nom' => 'Burger Dolce Vita', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Fast food', 'nom' => 'Burger classique', 'description' => 'Menu Dolce Vita Palace', 'prix' => 4000],
            ['categorie' => 'Fast food', 'nom' => 'Atlanta burger', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza Margherita — 7 000 F', 'description' => 'Premier tarif menu (7 000 / 9 000 F)', 'prix' => 7000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza Margherita — 9 000 F', 'description' => 'Second tarif menu (7 000 / 9 000 F)', 'prix' => 9000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza 4 fromages', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza royale — 6 000 F', 'description' => 'Premier tarif menu (6 000 / 8 000 F)', 'prix' => 6000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza royale — 8 000 F', 'description' => 'Second tarif menu (6 000 / 8 000 F)', 'prix' => 8000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza végétarienne — 6 000 F', 'description' => 'Premier tarif menu (6 000 / 8 000 F)', 'prix' => 6000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza végétarienne — 8 000 F', 'description' => 'Second tarif menu (6 000 / 8 000 F)', 'prix' => 8000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza poulet — 6 000 F', 'description' => 'Premier tarif menu (6 000 / 8 000 F)', 'prix' => 6000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza poulet — 8 000 F', 'description' => 'Second tarif menu (6 000 / 8 000 F)', 'prix' => 8000],
            ['categorie' => 'Fast food', 'nom' => 'Pizza fruits de mer', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],

            // ——— Garnitures ———
            ['categorie' => 'Garnitures', 'nom' => 'Attiéké sauté', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Attiéké nature', 'description' => 'Menu Dolce Vita Palace', 'prix' => 500],
            ['categorie' => 'Garnitures', 'nom' => 'Riz pilaf nature', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Purée de patate douce', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1500],
            ['categorie' => 'Garnitures', 'nom' => 'Jardinière de légumes', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1500],
            ['categorie' => 'Garnitures', 'nom' => 'Pommes de terre sautées', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1500],
            ['categorie' => 'Garnitures', 'nom' => 'Aloco', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Frites d\'igname', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Frites de patate douce', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Spaghetti nature', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Haricots verts sautés', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1500],
            ['categorie' => 'Garnitures', 'nom' => 'Haricots nature', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1500],

            // ——— Desserts ———
            ['categorie' => 'Desserts', 'nom' => 'Crème caramel renversée', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Desserts', 'nom' => 'Salade de fruits', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3000],
            ['categorie' => 'Desserts', 'nom' => 'Cake au citron', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3000],
            ['categorie' => 'Desserts', 'nom' => 'Crêpes au Nutella', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3000],
            ['categorie' => 'Desserts', 'nom' => 'Fondant au chocolat', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3000],
        ];

        $created = 0;
        foreach ($produits as $produitData) {
            $categorie = Category::where('nom', $produitData['categorie'])->first();

            if (! $categorie) {
                $this->command->warn('Catégorie non trouvée: '.$produitData['categorie']);

                continue;
            }

            Product::updateOrCreate(
                [
                    'nom' => $produitData['nom'],
                    'categorie_id' => $categorie->id,
                ],
                [
                    'description' => $produitData['description'],
                    'prix' => $produitData['prix'],
                    'disponible' => true,
                    'actif' => true,
                ]
            );
            $created++;
        }

        $this->command->info('✓ '.$created.' produits Dolce Vita Palace (sur '.count($produits).' entrées menu)');
    }
}
