<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Créer les rôles et permissions avec Spatie
        $this->call(SpatieRolesPermissionsSeeder::class);
        
        // Créer les catégories
        $this->call(CategorySeeder::class);
        
        // Créer les produits (après les catégories car ils en dépendent)
        $this->call(ProductSeeder::class);
        
        // Créer les tables
        $this->call(TableSeeder::class);
        
        // Créer ou récupérer un utilisateur admin
        $admin = User::firstOrCreate(
            ['email' => 'admin@admin.com'],
            [
                'name' => 'Admin User',
                'password' => bcrypt('password'),
            ]
        );
        
        if (!$admin->hasRole('admin')) {
            $admin->assignRole('admin');
        }

        // Liste des nouveaux caissiers
        $caissiers = [
            [
                'email' => 'bassolefatoumata@dolcevita.com',
                'name' => 'Bassole Fatoumata'
            ],
            [
                'email' => 'ahmed@dolcevita.com',
                'name' => 'Ahmed'
            ],
            [
                'email' => 'bambagracemariam@dolcevita.com',
                'name' => 'Bamba Grace Mariam'
            ],
        ];

        $allowedEmails = array_merge(['admin@admin.com'], array_column($caissiers, 'email'));

        // Supprimer les utilisateurs qui ne sont pas dans la liste autorisée
        User::whereNotIn('email', $allowedEmails)->delete();

        // Créer les nouveaux caissiers
        foreach ($caissiers as $caissierData) {
            $caissier = User::updateOrCreate(
                ['email' => $caissierData['email']],
                [
                    'name' => $caissierData['name'],
                    'password' => bcrypt('password'),
                ]
            );
            
            if (!$caissier->hasRole('caissier')) {
                $caissier->assignRole('caissier');
            }
        }
    }
}
