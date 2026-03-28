<?php

namespace Database\Seeders;

use App\Models\Permission;
use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Créer les rôles
        $admin = Role::firstOrCreate(
            ['name' => 'admin'],
            [
                'display_name' => 'Administrateur',
                'description' => 'Accès complet à toutes les fonctionnalités',
            ]
        );

        $manager = Role::firstOrCreate(
            ['name' => 'manager'],
            [
                'display_name' => 'Manager',
                'description' => 'Gestion du restaurant (sauf paramètres système)',
            ]
        );

        $caissier = Role::firstOrCreate(
            ['name' => 'caissier'],
            [
                'display_name' => 'Caissier',
                'description' => 'Gestion de la caisse et des paiements',
            ]
        );

        $serveur = Role::firstOrCreate(
            ['name' => 'serveur'],
            [
                'display_name' => 'Serveur',
                'description' => 'Prise de commandes et gestion des tables',
            ]
        );

        // Admin : Toutes les permissions
        $allPermissions = Permission::all();
        $admin->permissions()->syncWithoutDetaching($allPermissions);

        // Manager : Presque toutes les permissions (sauf settings système)
        $managerPermissions = Permission::whereNotIn('group', ['settings'])->get();
        $manager->permissions()->syncWithoutDetaching($managerPermissions);

        // Caissier : Caisse, paiements, commandes (vue), tables (vue)
        $caissierPermissions = Permission::whereIn('name', [
            'access_cashier',
            'process_payments',
            'view_payments',
            'view_orders',
            'view_tables',
            'view_menu',
            'view_customers',
            'view_reservations',
            'view_statistics',
            'manage_sessions',
        ])->get();
        $caissier->permissions()->syncWithoutDetaching($caissierPermissions);

        // Serveur : Commandes, tables, menu (vue), réservations (vue)
        $serveurPermissions = Permission::whereIn('name', [
            'create_orders',
            'view_orders',
            'update_orders',
            'update_order_status',
            'view_tables',
            'update_table_status',
            'view_menu',
            'view_customers',
            'view_reservations',
        ])->get();
        $serveur->permissions()->syncWithoutDetaching($serveurPermissions);
    }
}
