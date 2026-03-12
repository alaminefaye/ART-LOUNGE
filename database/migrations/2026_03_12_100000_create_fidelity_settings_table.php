<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fidelity_settings', function (Blueprint $table) {
            $table->id();
            // Attribution : pour chaque (fcfa_pour_1_point) FCFA dépensés, le client gagne 1 point
            $table->unsignedInteger('fcfa_pour_1_point')->default(1000)->comment('FCFA à dépenser pour gagner 1 point');
            // Utilisation : 1 point = (valeur_fcfa_1_point) FCFA de réduction
            $table->decimal('valeur_fcfa_1_point', 10, 2)->default(100)->comment('Valeur en FCFA d\'1 point pour réduire la facture');
            $table->boolean('actif')->default(true);
            $table->timestamps();
        });

        // Une seule ligne de paramètres
        DB::table('fidelity_settings')->insert([
            'fcfa_pour_1_point' => 1000,
            'valeur_fcfa_1_point' => 100,
            'actif' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('fidelity_settings');
    }
};
