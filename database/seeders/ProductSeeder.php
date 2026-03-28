<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Seeder;

/**
 * MENU DOLCE VITA PALACE — seuls ces produits (le reste est retiré si possible).
 * Pizzas à double tarif : deux lignes (prix distincts).
 */
class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $menuOfficiel = [
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

            // ——— MENU BOISSONS — Cocktails alcoolisés ———
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Mojito', 'description' => 'Citron, sirop de canne, menthe fraîche, rhum blanc — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Pina colada', 'description' => 'Rhum, jus d\'ananas, lait de coco, sirop de canne — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Rosa beach', 'description' => 'Sirop de citron, sirop d\'orange, jus d\'ananas, grenadine — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Bora Bora', 'description' => 'Passion, jus de citron, ananas, grenadine — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Long island', 'description' => 'Rhum, tequila, vodka, gin, Cointreau, Coca-Cola — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Margharita', 'description' => 'Cointreau, citron — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Limonade', 'description' => 'Jus de citron, sirop de canne, tranche de citron, sirop de menthe — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Chericoco', 'description' => 'Crème fraîche, crème chantilly, lait de coco, Nutella, rhum blanc — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Dolce Vita Palace sunset', 'description' => 'Jack Daniel\'s, miel, jus de citron, sirop de gingembre — Menu Dolce Vita Palace', 'prix' => 10000],

            // ——— MENU BOISSONS — Cocktails sans alcool ———
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Mojito', 'description' => 'Citron, sirop de canne, menthe fraîche — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Pina colada', 'description' => 'Jus d\'ananas, lait de coco, sirop de canne — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Rosa beach', 'description' => 'Sirop de citron, sirop d\'orange, jus d\'ananas, grenadine — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Bora Bora', 'description' => 'Passion, jus de citron, ananas, grenadine — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Margharita', 'description' => 'Cointreau, citron — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Limonade', 'description' => 'Jus de citron, sirop de canne, tranche de citron, sirop de menthe — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Chericoco', 'description' => 'Crème fraîche, crème chantilly, lait de coco, Nutella — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Dolce Vita Palace sunset', 'description' => 'Miel, jus de citron, sirop de gingembre — Menu Dolce Vita Palace', 'prix' => 8000],
        ];

        $allowedProductIds = [];

        foreach ($menuOfficiel as $produitData) {
            $categorie = Category::where('nom', $produitData['categorie'])->first();

            if (! $categorie) {
                $this->command->warn('Catégorie non trouvée: '.$produitData['categorie']);

                continue;
            }

            $p = Product::updateOrCreate(
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
            $allowedProductIds[] = $p->id;
        }

        // Retirer tout produit qui n’est pas dans ce menu (si aucune commande ne le référence)
        $removed = Product::query()
            ->whereNotIn('id', $allowedProductIds)
            ->whereDoesntHave('commandes')
            ->delete();

        $blocked = Product::query()
            ->whereNotIn('id', $allowedProductIds)
            ->whereHas('commandes')
            ->count();

        if ($blocked > 0) {
            $this->command->warn(
                "{$blocked} ancien(s) produit(s) hors menu conservé(s) (déjà présent(s) sur des commandes — suppression manuelle ou base de test)."
            );
        }

        // Catégories hors menu sans aucun produit
        $names = DolceVitaMenu::categoryNames();
        $deletedCats = Category::whereNotIn('nom', $names)
            ->whereDoesntHave('produits')
            ->delete();

        $this->command->info('✓ '.count($allowedProductIds).' produits Menu Dolce Vita Palace ('.count($menuOfficiel).' lignes menu)'.
            ($removed ? " — {$removed} ancien(s) produit(s) supprimé(s)" : '').
            ($deletedCats ? " — {$deletedCats} catégorie(s) vide(s) supprimée(s)" : ''));
    }
}
