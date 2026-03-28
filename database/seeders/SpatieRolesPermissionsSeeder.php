<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class SpatieRolesPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Reset cached roles and permissions
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // Create permissions with groups
        $permissionsByGroup = [
            'users' => ['manage_users', 'view_users'],
            'roles' => ['manage_roles', 'view_roles'],
            'tables' => ['manage_tables', 'view_tables', 'update_table_status'],
            'menu' => ['manage_menu', 'view_menu', 'toggle_product_availability'],
            'orders' => ['create_orders', 'view_orders', 'update_orders', 'update_order_status', 'cancel_orders'],
            'stock' => ['manage_stock', 'view_stock', 'manage_suppliers', 'manage_recipes', 'perform_inventory'],
            'cashier' => ['access_cashier', 'manage_cashier', 'view_cashier', 'process_payments', 'generate_invoices', 'manage_sessions'],
            'reservations' => ['manage_reservations', 'view_reservations', 'confirm_reservations'],
            'customers' => ['manage_customers', 'view_customers', 'manage_loyalty', 'manage_promotions', 'view_avis', 'manage_avis', 'manage_fidelity', 'view_fidelity'],
            'reports' => ['view_reports', 'export_reports', 'view_dashboard', 'view_statistics'],
            'settings' => ['manage_settings', 'view_settings', 'manage_payment_methods', 'view_payment_methods'],
        ];

        foreach ($permissionsByGroup as $group => $permissions) {
            foreach ($permissions as $permission) {
                Permission::firstOrCreate(
                    ['name' => $permission], 
                    ['group' => $group]
                );
            }
        }

        // Create roles and assign permissions
        $admin = Role::firstOrCreate(['name' => 'admin', 'guard_name' => 'web']);
        $admin->syncPermissions(Permission::all());

        $manager = Role::firstOrCreate(['name' => 'manager', 'guard_name' => 'web']);
        $manager->syncPermissions([
            'view_dashboard', 'manage_tables', 'view_tables', 'manage_menu', 'view_menu',
            'create_orders', 'view_orders', 'update_orders', 'update_order_status', 'cancel_orders',
            'manage_stock', 'view_stock', 'manage_reservations', 'view_roles', 'view_users',
            'view_reservations', 'manage_customers', 'view_customers', 'manage_promotions',
            'view_reports', 'export_reports', 'manage_settings', 'view_settings', 'view_avis',
            'manage_loyalty', 'view_fidelity', 'manage_fidelity', 'manage_sessions', 'access_cashier'
        ]);

        $caissier = Role::firstOrCreate(['name' => 'caissier', 'guard_name' => 'web']);
        $caissier->syncPermissions([
            'view_dashboard', 'view_tables', 'view_menu', 'create_orders', 'view_orders', 'update_orders',
            'manage_cashier', 'view_cashier', 'process_payments', 'generate_invoices',
            'view_customers', 'view_reports', 'update_order_status', 'manage_sessions', 'access_cashier'
        ]);

        $serveur = Role::firstOrCreate(['name' => 'serveur', 'guard_name' => 'web']);
        $serveur->syncPermissions([
            'view_dashboard', 'view_tables', 'view_menu', 'create_orders', 'view_orders', 'update_orders', 'view_reservations', 'update_order_status', 'update_table_status'
        ]);

        // Rôle client pour les utilisateurs de l'application mobile
        $client = Role::firstOrCreate(['name' => 'client', 'guard_name' => 'web']);
        $client->syncPermissions([
            'create_orders',  // Créer des commandes
            'view_orders',   // Voir les commandes (leurs propres commandes)
            'update_orders', // Modifier leurs propres commandes (ajouter des produits)
        ]);

        $this->command->info('✓ Rôles et permissions créés avec Spatie !');
    }
}

