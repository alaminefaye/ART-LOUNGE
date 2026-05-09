<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('commandes', function (Blueprint $table) {
            $table->boolean('is_passager')->default(false)->after('notes');
            $table->unsignedBigInteger('trajet_id')->nullable()->after('is_passager');
            $table->string('numero_siege', 50)->nullable()->after('trajet_id');

            $table
                ->foreign('trajet_id')
                ->references('id')
                ->on('trajets')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('commandes', function (Blueprint $table) {
            $table->dropForeign(['trajet_id']);
            $table->dropColumn(['is_passager', 'trajet_id', 'numero_siege']);
        });
    }
};
