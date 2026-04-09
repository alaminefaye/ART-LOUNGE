<?php

namespace Database\Seeders;

use App\Models\Table;
use App\Enums\TableType;
use App\Enums\TableStatus;
use App\Services\QRCodeService;
use Illuminate\Database\Seeder;

class TableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $qrCodeService = new QRCodeService();

        $tables = [];

        // Tables simples (30 tables) + sous-tables (.1, .2, .3)
        for ($i = 1; $i <= 30; $i++) {
            $capacite = $i <= 10 ? 2 : ($i <= 25 ? 4 : 6);

            // Table principale
            $tables[] = [
                'numero' => 'T' . $i,
                'type' => TableType::Simple->value,
                'capacite' => $capacite,
                'statut' => TableStatus::Libre->value,
                'actif' => true,
            ];

            // Sous-tables
            for ($j = 1; $j <= 3; $j++) {
                $tables[] = [
                    'numero' => 'T' . $i . '.' . $j,
                    'type' => TableType::Simple->value,
                    'capacite' => $capacite,
                    'statut' => TableStatus::Libre->value,
                    'actif' => true,
                ];
            }
        }

        // Tables VIP (3 tables)
        for ($i = 1; $i <= 3; $i++) {
            $tables[] = [
                'numero' => 'VIP' . $i,
                'type' => TableType::VIP->value,
                'capacite' => $i == 1 ? 4 : ($i == 2 ? 6 : 8),
                'statut' => TableStatus::Libre->value,
                'prix' => 50000 + (($i - 1) * 25000),
                'actif' => true,
            ];
        }

        foreach ($tables as $tableData) {
            // Créer ou mettre à jour la table
            $table = Table::updateOrCreate(
                ['numero' => $tableData['numero']],
                $tableData
            );

            // Générer le QR Code si pas déjà généré
            if (!$table->qr_code) {
                try {
                    $qrCodePath = $qrCodeService->generateForTable($table);
                    $table->update(['qr_code' => $qrCodePath]);
                    $this->command->info("✓ QR Code généré pour la table {$table->numero}");
                } catch (\Exception $e) {
                    $this->command->warn("⚠ Impossible de générer le QR Code pour {$table->numero}: " . $e->getMessage());
                }
            }
        }

        // Supprimer les tables en trop si nécessaire (Nettoyage)
        $numerosAcceptes = array_column($tables, 'numero');
        Table::whereNotIn('numero', $numerosAcceptes)->delete();

        $this->command->info("✓ " . count($tables) . " tables configurées avec succès!");
        $this->command->info("  - 30 tables simples principales (T1 à T30)");
        $this->command->info("  - 90 sous-tables (T1.1, T1.2, ..., T30.3)");
        $this->command->info("  - 3 tables VIP (VIP1 à VIP3)");
    }
}
