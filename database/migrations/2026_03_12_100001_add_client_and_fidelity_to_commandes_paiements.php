<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('commandes', function (Blueprint $table) {
            $table->foreignId('client_id')->nullable()->after('user_id')->constrained('clients')->onDelete('set null');
        });

        Schema::table('paiements', function (Blueprint $table) {
            $table->foreignId('client_id')->nullable()->after('user_id')->constrained('clients')->onDelete('set null');
            $table->unsignedInteger('points_utilises')->nullable()->after('notes')->comment('Nombre de points utilisés (si moyen = points_fidelite)');
        });

        // Étendre l\'enum MySQL pour moyen_paiement (ajouter points_fidelite)
        DB::statement("ALTER TABLE paiements MODIFY COLUMN moyen_paiement ENUM('especes', 'wave', 'orange_money', 'carte_bancaire', 'points_fidelite') DEFAULT 'especes'");
    }

    public function down(): void
    {
        Schema::table('commandes', function (Blueprint $table) {
            $table->dropForeign(['client_id']);
        });
        Schema::table('paiements', function (Blueprint $table) {
            $table->dropForeign(['client_id']);
            $table->dropColumn('points_utilises');
        });
        DB::statement("ALTER TABLE paiements MODIFY COLUMN moyen_paiement ENUM('especes', 'wave', 'orange_money', 'carte_bancaire') DEFAULT 'especes'");
    }
};
