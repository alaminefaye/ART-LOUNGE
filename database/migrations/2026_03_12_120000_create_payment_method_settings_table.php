<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_method_settings', function (Blueprint $table) {
            $table->id();
            $table->boolean('wave_enabled')->default(true);
            $table->boolean('orange_money_enabled')->default(true);
            $table->timestamps();
        });

        DB::table('payment_method_settings')->insert([
            'wave_enabled' => true,
            'orange_money_enabled' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_method_settings');
    }
};
