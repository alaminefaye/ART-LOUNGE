<?php

namespace Database\Seeders;

use App\Models\Permission;
use Illuminate\Database\Seeder;

class PermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $permissions = [
            // Gestion des utilisateurs
            ['name' => 'manage_users', 'display_name' => 'Gérer les utilisateurs', 'description' => 'Créer, modifier, supprimer des utilisateurs', 'group' => 'users'],
            ['name' => 'view_users', 'display_name' => 'Voir les utilisateurs', 'description' => 'Consulter la liste des utilisateurs', 'group' => 'users'],
            
            // Gestion des rôles et permissions
            ['name' => 'manage_roles', 'display_name' => 'Gérer les rôles', 'description' => 'Créer, modifier, supprimer des rôles', 'group' => 'roles'],
            ['name' => 'view_roles', 'display_name' => 'Voir les rôles', 'description' => 'Consulter la liste des rôles', 'group' => 'roles'],
            ['name' => 'assign_roles', 'display_name' => 'Attribuer des rôles', 'description' => 'Attribuer des rôles aux utilisateurs', 'group' => 'roles'],
            
            // Gestion des tables
            ['name' => 'manage_tables', 'display_name' => 'Gérer les tables', 'description' => 'Créer, modifier, supprimer des tables', 'group' => 'tables'],
            ['name' => 'view_tables', 'display_name' => 'Voir les tables', 'description' => 'Consulter la liste des tables', 'group' => 'tables'],
            ['name' => 'update_table_status', 'display_name' => 'Mettre à jour le statut des tables', 'description' => 'Changer le statut des tables', 'group' => 'tables'],
            
            // Gestion du menu
            ['name' => 'manage_menu', 'display_name' => 'Gérer le menu', 'description' => 'Créer, modifier, supprimer des produits et catégories', 'group' => 'menu'],
            ['name' => 'view_menu', 'display_name' => 'Voir le menu', 'description' => 'Consulter le menu', 'group' => 'menu'],
            ['name' => 'manage_categories', 'display_name' => 'Gérer les catégories', 'description' => 'Créer, modifier, supprimer des catégories', 'group' => 'menu'],
            
            // Gestion des commandes
            ['name' => 'create_orders', 'display_name' => 'Créer des commandes', 'description' => 'Passer des commandes', 'group' => 'orders'],
            ['name' => 'view_orders', 'display_name' => 'Voir les commandes', 'description' => 'Consulter les commandes', 'group' => 'orders'],
            ['name' => 'update_orders', 'display_name' => 'Modifier les commandes', 'description' => 'Modifier les commandes en cours', 'group' => 'orders'],
            ['name' => 'cancel_orders', 'display_name' => 'Annuler les commandes', 'description' => 'Annuler des commandes', 'group' => 'orders'],
            ['name' => 'update_order_status', 'display_name' => 'Mettre à jour le statut des commandes', 'description' => 'Changer le statut des commandes', 'group' => 'orders'],
            
            // Gestion du stock
            ['name' => 'manage_stock', 'display_name' => 'Gérer le stock', 'description' => 'Gérer les ingrédients et le stock', 'group' => 'stock'],
            ['name' => 'view_stock', 'display_name' => 'Voir le stock', 'description' => 'Consulter l\'état du stock', 'group' => 'stock'],
            ['name' => 'manage_suppliers', 'display_name' => 'Gérer les fournisseurs', 'description' => 'Gérer les fournisseurs', 'group' => 'stock'],
            ['name' => 'create_purchase_orders', 'display_name' => 'Créer des bons de commande', 'description' => 'Créer des bons de commande fournisseurs', 'group' => 'stock'],
            ['name' => 'manage_inventory', 'display_name' => 'Gérer les inventaires', 'description' => 'Créer et valider des inventaires', 'group' => 'stock'],
            
            // Gestion de la caisse et paiements
            ['name' => 'access_cashier', 'display_name' => 'Accéder à la caisse', 'description' => 'Accéder à l\'interface de caisse', 'group' => 'cashier'],
            ['name' => 'process_payments', 'display_name' => 'Traiter les paiements', 'description' => 'Valider les paiements', 'group' => 'cashier'],
            ['name' => 'view_payments', 'display_name' => 'Voir les paiements', 'description' => 'Consulter les paiements', 'group' => 'cashier'],
            ['name' => 'refund_payments', 'display_name' => 'Rembourser les paiements', 'description' => 'Effectuer des remboursements', 'group' => 'cashier'],
            
            // Gestion des réservations
            ['name' => 'manage_reservations', 'display_name' => 'Gérer les réservations', 'description' => 'Créer, modifier, annuler des réservations', 'group' => 'reservations'],
            ['name' => 'view_reservations', 'display_name' => 'Voir les réservations', 'description' => 'Consulter les réservations', 'group' => 'reservations'],
            ['name' => 'confirm_reservations', 'display_name' => 'Confirmer les réservations', 'description' => 'Confirmer ou refuser des réservations', 'group' => 'reservations'],
            
            // Gestion des clients et fidélité
            ['name' => 'manage_customers', 'display_name' => 'Gérer les clients', 'description' => 'Gérer les clients et leur fidélité', 'group' => 'customers'],
            ['name' => 'view_customers', 'display_name' => 'Voir les clients', 'description' => 'Consulter les clients', 'group' => 'customers'],
            ['name' => 'manage_loyalty', 'display_name' => 'Gérer la fidélité', 'description' => 'Configurer le programme de fidélité', 'group' => 'customers'],
            ['name' => 'manage_promotions', 'display_name' => 'Gérer les promotions', 'description' => 'Créer et gérer des promotions', 'group' => 'customers'],
            ['name' => 'view_avis', 'display_name' => 'Voir les avis', 'description' => 'Consulter les avis clients', 'group' => 'customers'],
            
            // Statistiques et rapports
            ['name' => 'view_statistics', 'display_name' => 'Voir les statistiques', 'description' => 'Accéder aux statistiques', 'group' => 'reports'],
            ['name' => 'view_reports', 'display_name' => 'Voir les rapports', 'description' => 'Consulter les rapports', 'group' => 'reports'],
            ['name' => 'export_reports', 'display_name' => 'Exporter les rapports', 'description' => 'Exporter les rapports en PDF/Excel', 'group' => 'reports'],
            ['name' => 'view_dashboard', 'display_name' => 'Voir le dashboard', 'description' => 'Accéder au tableau de bord principal', 'group' => 'reports'],
            
            // Paramètres système
            ['name' => 'manage_settings', 'display_name' => 'Gérer les paramètres', 'description' => 'Configurer les paramètres système', 'group' => 'settings'],
            ['name' => 'view_logs', 'display_name' => 'Voir les logs', 'description' => 'Consulter les logs système', 'group' => 'settings'],
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(
                ['name' => $permission['name']],
                $permission
            );
        }
    }
}
