<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('commandes')) {
            return;
        }

        $driver = DB::getDriverName();
        if ($driver !== 'mysql') {
            return;
        }

        DB::statement('ALTER TABLE commandes DROP FOREIGN KEY commandes_table_id_foreign');
        DB::statement('ALTER TABLE commandes MODIFY table_id BIGINT UNSIGNED NULL');
        DB::statement('ALTER TABLE commandes ADD CONSTRAINT commandes_table_id_foreign FOREIGN KEY (table_id) REFERENCES tables(id) ON DELETE SET NULL');
    }

    public function down(): void
    {
        if (!Schema::hasTable('commandes')) {
            return;
        }

        $driver = DB::getDriverName();
        if ($driver !== 'mysql') {
            return;
        }

        DB::statement('ALTER TABLE commandes DROP FOREIGN KEY commandes_table_id_foreign');
        DB::statement('ALTER TABLE commandes MODIFY table_id BIGINT UNSIGNED NOT NULL');
        DB::statement('ALTER TABLE commandes ADD CONSTRAINT commandes_table_id_foreign FOREIGN KEY (table_id) REFERENCES tables(id) ON DELETE CASCADE');
    }
};

