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
            // ——— Tapas ———
            ['categorie' => 'Tapas', 'nom' => 'Calamars sautés', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3500],
            ['categorie' => 'Tapas', 'nom' => 'Gambas panées', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3500],
            ['categorie' => 'Tapas', 'nom' => 'Ailerons de poulet', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3500],
            ['categorie' => 'Tapas', 'nom' => 'Poulet pané', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Tapas', 'nom' => 'Burger maison', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6500],

            // ——— Entrées ———
            ['categorie' => 'Entrées', 'nom' => 'Salade Dolce Vita', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées', 'nom' => 'Salade de crevettes aux agrumes', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Entrées', 'nom' => 'Salade César', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées', 'nom' => 'Salade de gésiers', 'description' => 'Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'Entrées', 'nom' => 'Salade verte', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3000],
            ['categorie' => 'Entrées', 'nom' => 'Salade niçoise', 'description' => 'Menu Dolce Vita Palace', 'prix' => 4000],
            ['categorie' => 'Entrées', 'nom' => 'Salade de gambas', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Entrées', 'nom' => 'Salade de crevettes pili-pili', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées', 'nom' => 'Fraîcheur d\'avocat et crevettes', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées', 'nom' => 'Salade fondante exotique', 'description' => 'Menu Dolce Vita Palace', 'prix' => 4000],
            ['categorie' => 'Entrées', 'nom' => 'Salade croustillante de pintade', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Entrées', 'nom' => 'Salade chicken wings', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6000],
            ['categorie' => 'Entrées', 'nom' => 'Salade ken nuggets', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6000],

            // ——— Poissons & fruits de mer ———
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Duo de saumon et gambas', 'description' => 'Menu Dolce Vita Palace', 'prix' => 17000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Pavé de mérou', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Dos de bar', 'description' => 'Menu Dolce Vita Palace', 'prix' => 14000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Carpe braisée', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Carpe grillée', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Soupe du pêcheur', 'description' => 'Menu Dolce Vita Palace', 'prix' => 15000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Soso frit', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Sole meunière', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Sole frite', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Gambas sautées', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Langouste gratinée', 'description' => 'Menu Dolce Vita Palace', 'prix' => 14000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Escargots sautés', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Filet de capitaine aux épinards', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Pavé royal de saumon sauce roquefort', 'description' => 'Menu Dolce Vita Palace', 'prix' => 15000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Snack de sole marinade Dolce Vita', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Calamars panés aux épices américaines frites', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Sauté de calamars aux épices américaines pommes vapeur', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Snack de gambas tigrées à l\'ail', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Poissons & fruits de mer', 'nom' => 'Gambas tigrées au beurre d\'agrumes et chorizo', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],

            // ——— Viandes ———
            ['categorie' => 'Viandes', 'nom' => 'Entrecôte Angus poivrée au thym', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Viandes', 'nom' => 'Filet de bœuf en tagliata', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Viandes', 'nom' => 'Steak de filet de bœuf', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Viandes', 'nom' => 'T-Bone poivré aux herbes aromatiques', 'description' => 'Menu Dolce Vita Palace', 'prix' => 14000],
            ['categorie' => 'Viandes', 'nom' => 'Côte de bœuf', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Viandes', 'nom' => 'Steak grillé, sauce crème champignons', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Viandes', 'nom' => 'Pavé de steak au poivre', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Viandes', 'nom' => 'Mignon de steak rôti', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Viandes', 'nom' => 'Côtelettes d\'agneau', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],

            // ——— Volailles & spécialités ———
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Volaille à la crème (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Cuisse de canard sauce foie gras', 'description' => 'Menu Dolce Vita Palace', 'prix' => 15000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Poulet basquaise, riz au curry (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Pintade Dolce Vita (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 15000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Choukouya de poulet', 'description' => 'Demi - Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Choukouya de poulet (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Poulet sauté', 'description' => 'Demi - Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Poulet sauté (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Poulet grillé', 'description' => 'Demi - Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Poulet grillé (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Choukouya de pintade', 'description' => 'Demi - Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Choukouya de pintade (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 14000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Choukouya de lapin (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Kedjenou de lapin (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Lapin grillé (entier)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Poulet frit au beurre classique (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Poulet au curry (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Snack de pintade à l\'ail (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Pintade frite au beurre (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7500],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Snack de lapin à l\'origan (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Lapin frit à la moutarde à l\'ancienne (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Sauté de lapin aux épices jamaïcaines (½)', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Blanquette de poulet aux champignons de Paris', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Volailles & spécialités', 'nom' => 'Magret de canard gratiné', 'description' => 'Menu Dolce Vita Palace', 'prix' => 14000],

            // ——— Brochettes ———
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de poulet', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de bar', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10500],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes d\'escargots', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de gambas', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de bœuf', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de mouton', 'description' => 'Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes de mérou', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],
            ['categorie' => 'Brochettes', 'nom' => 'Brochettes Dolce Vita', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],

            // ——— Plats africains ———
            ['categorie' => 'Plats africains', 'nom' => 'Kedjenou de poulet africain', 'description' => 'Menu Dolce Vita Palace', 'prix' => 6000],
            ['categorie' => 'Plats africains', 'nom' => 'Kedjenou de pintade entière', 'description' => 'Menu Dolce Vita Palace', 'prix' => 12000],
            ['categorie' => 'Plats africains', 'nom' => 'Kedjenou d\'escargots', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Plats africains', 'nom' => 'Braisé de queue de bœuf', 'description' => 'Menu Dolce Vita Palace', 'prix' => 9000],

            // ——— Pâtes ———
            ['categorie' => 'Pâtes', 'nom' => 'Tagliatelles au poulet et champignons', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Pâtes', 'nom' => 'Linguine aux fruits de mer', 'description' => 'Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'Pâtes', 'nom' => 'Penne arrabbiata', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'Pâtes', 'nom' => 'Fusilli crémeux', 'description' => 'Menu Dolce Vita Palace', 'prix' => 7000],
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
            ['categorie' => 'Garnitures', 'nom' => 'Attiéké', 'description' => 'Menu Dolce Vita Palace', 'prix' => 500],
            ['categorie' => 'Garnitures', 'nom' => 'Gratin dauphinois', 'description' => 'Menu Dolce Vita Palace', 'prix' => 2500],
            ['categorie' => 'Garnitures', 'nom' => 'Pommes de terre sautées', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Frites de pommes de terre', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1500],
            ['categorie' => 'Garnitures', 'nom' => 'Frites d\'igname', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Purée de pommes de terre', 'description' => 'Menu Dolce Vita Palace', 'prix' => 2000],
            ['categorie' => 'Garnitures', 'nom' => 'Légumes de saison', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Alloco', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Riz', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Attiéké sauté', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Purée de patate douce', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1500],
            ['categorie' => 'Garnitures', 'nom' => 'Frites de patate douce', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Spaghetti nature', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1000],
            ['categorie' => 'Garnitures', 'nom' => 'Haricots verts sautés', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1500],
            ['categorie' => 'Garnitures', 'nom' => 'Haricots nature', 'description' => 'Menu Dolce Vita Palace', 'prix' => 1500],

            // ——— Nos sauces ———
            ['categorie' => 'Nos sauces', 'nom' => 'Sauce crème champignons', 'description' => 'Menu Dolce Vita Palace', 'prix' => 0],
            ['categorie' => 'Nos sauces', 'nom' => 'Sauce poivre noir', 'description' => 'Menu Dolce Vita Palace', 'prix' => 0],
            ['categorie' => 'Nos sauces', 'nom' => 'Sauce crème curry', 'description' => 'Menu Dolce Vita Palace', 'prix' => 0],
            ['categorie' => 'Nos sauces', 'nom' => 'Sauce vierge', 'description' => 'Menu Dolce Vita Palace', 'prix' => 0],
            ['categorie' => 'Nos sauces', 'nom' => 'Sauce tomate', 'description' => 'Menu Dolce Vita Palace', 'prix' => 0],
            ['categorie' => 'Nos sauces', 'nom' => 'Sauce piment', 'description' => 'Menu Dolce Vita Palace', 'prix' => 0],
            ['categorie' => 'Nos sauces', 'nom' => 'Sauce Dolce Vita', 'description' => 'Menu Dolce Vita Palace', 'prix' => 0],

            // ——— Desserts ———
            ['categorie' => 'Desserts', 'nom' => 'Crème brûlée', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Desserts', 'nom' => 'Crêpes à la vanille', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3000],
            ['categorie' => 'Desserts', 'nom' => 'Crêpes Nutella & fruits', 'description' => 'Menu Dolce Vita Palace', 'prix' => 4000],
            ['categorie' => 'Desserts', 'nom' => 'Tiramisu aux fruits rouges', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3000],
            ['categorie' => 'Desserts', 'nom' => 'Glace', 'description' => 'Menu Dolce Vita Palace', 'prix' => 2000],
            ['categorie' => 'Desserts', 'nom' => 'Salade de fruits', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3000],
            ['categorie' => 'Desserts', 'nom' => 'Crème caramel renversée', 'description' => 'Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'Desserts', 'nom' => 'Cake au citron', 'description' => 'Menu Dolce Vita Palace', 'prix' => 3000],
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
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Passion maï-taï', 'description' => 'Cointreau, triple sec, citron vert, fruit de la passion, rhum — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Negroni', 'description' => 'Gin, vermouth rouge, Campari — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Blue Hawaï', 'description' => 'Rhum ou vodka, curacao bleu, citron vert, sucre de canne — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'As de pique', 'description' => 'Liqueur de pêche, purée de pêche, sirop de vanille, Prosecco — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails alcoolisés', 'nom' => 'Sex on the beach', 'description' => 'Vodka, liqueur de pêche, jus d\'orange, jus de cranberry — Menu Dolce Vita Palace', 'prix' => 5000],

            // ——— MENU BOISSONS — Cocktails sans alcool ———
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Mojito', 'description' => 'Citron, sirop de canne, menthe fraîche — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Pina colada', 'description' => 'Jus d\'ananas, lait de coco, sirop de canne — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Rosa beach', 'description' => 'Sirop de citron, sirop d\'orange, jus d\'ananas, grenadine — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Bora Bora', 'description' => 'Passion, jus de citron, ananas, grenadine — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Margharita', 'description' => 'Cointreau, citron — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Limonade', 'description' => 'Jus de citron, sirop de canne, tranche de citron, sirop de menthe — Menu Dolce Vita Palace', 'prix' => 4500],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Chericoco', 'description' => 'Crème fraîche, crème chantilly, lait de coco, Nutella — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Dolce Vita Palace sunset', 'description' => 'Miel, jus de citron, sirop de gingembre — Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'MENU BOISSONS — Cocktails sans alcool', 'nom' => 'Passion maï-taï', 'description' => 'Citron vert, fruit de la passion, sirop d\'orange — Menu Dolce Vita Palace', 'prix' => 4500],

            // ——— MENU BOISSONS — Cocktails signature (alcoolisés) ———
            ['categorie' => 'MENU BOISSONS — Cocktails signature (alcoolisés)', 'nom' => 'Corossol dive', 'description' => 'Pulpe de corossol, vodka ou gin, triple sec, cassis, passion, citron — Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'MENU BOISSONS — Cocktails signature (alcoolisés)', 'nom' => 'Pêche Bellini', 'description' => 'Sirop de pêche, allongé au Prosecco — Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'MENU BOISSONS — Cocktails signature (alcoolisés)', 'nom' => 'Red fresh', 'description' => 'Gingembre, bissap, jus d\'orange, triple sec, rhum blanc — Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'MENU BOISSONS — Cocktails signature (alcoolisés)', 'nom' => 'Ginger smash', 'description' => 'Gingembre, concombre, citron, sirop de vanille, vodka — Menu Dolce Vita Palace', 'prix' => 10000],
            ['categorie' => 'MENU BOISSONS — Cocktails signature (alcoolisés)', 'nom' => 'Le Dolce Vita Palace', 'description' => 'Création signature du chef barman — Menu Dolce Vita Palace', 'prix' => 12000],

            // ——— MENU BOISSONS — Cocktails signature (sans alcool) ———
            ['categorie' => 'MENU BOISSONS — Cocktails signature (sans alcool)', 'nom' => 'Corossol fresh', 'description' => 'Pulpe de corossol, jus de passion, cassis, citron, eau pétillante — Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'MENU BOISSONS — Cocktails signature (sans alcool)', 'nom' => 'Pêche Bellini soft', 'description' => 'Sirop de pêche, jus de raisin blanc pétillant — Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'MENU BOISSONS — Cocktails signature (sans alcool)', 'nom' => 'Red fresh soft', 'description' => 'Gingembre, bissap, jus d\'orange, citron — Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'MENU BOISSONS — Cocktails signature (sans alcool)', 'nom' => 'Ginger smash soft', 'description' => 'Gingembre, concombre, citron, sirop de vanille, eau pétillante — Menu Dolce Vita Palace', 'prix' => 8000],
            ['categorie' => 'MENU BOISSONS — Cocktails signature (sans alcool)', 'nom' => 'Le Dolce Vita Palace soft', 'description' => 'Création signature sans alcool du chef barman — Menu Dolce Vita Palace', 'prix' => 10000],

            // ——— MENU BOISSONS — Shots classiques & tendances ———
            ['categorie' => 'MENU BOISSONS — Shots classiques & tendances', 'nom' => 'Kamikaze', 'description' => 'Vodka, triple sec, citron — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Shots classiques & tendances', 'nom' => 'Tequila Sunrise Shot', 'description' => 'Tequila, orange, grenadine — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Shots classiques & tendances', 'nom' => 'B52', 'description' => 'Baileys, Kahlua, Grand Marnier — Menu Dolce Vita Palace', 'prix' => 5000],

            // ——— MENU BOISSONS — Shots aromatisés ———
            ['categorie' => 'MENU BOISSONS — Shots aromatisés', 'nom' => 'Passion Shot', 'description' => 'Passion, rhum brut, citron — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Shots aromatisés', 'nom' => 'Vanilla Shot', 'description' => 'Vodka, vanille, sucre — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Shots aromatisés', 'nom' => 'Bissap Shot', 'description' => 'Bissap, rhum, citron — Menu Dolce Vita Palace', 'prix' => 5000],

            // ——— MENU BOISSONS — Shots signature Dolce Vita ———
            ['categorie' => 'MENU BOISSONS — Shots signature Dolce Vita', 'nom' => 'Dolce Fire', 'description' => 'Rhum, gingembre, citron — Menu Dolce Vita Palace', 'prix' => 5000],
            ['categorie' => 'MENU BOISSONS — Shots signature Dolce Vita', 'nom' => 'Shot Flambé', 'description' => 'Cointreau, rhum rouge, sucre — Menu Dolce Vita Palace', 'prix' => 7000],
            ['categorie' => 'MENU BOISSONS — Shots signature Dolce Vita', 'nom' => 'Dolce Vita Signature', 'description' => 'Jack Daniel\'s, miel, gingembre — Menu Dolce Vita Palace', 'prix' => 8000],
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
