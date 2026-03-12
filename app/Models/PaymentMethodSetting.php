<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PaymentMethodSetting extends Model
{
    protected $table = 'payment_method_settings';

    protected $fillable = [
        'wave_enabled',
        'orange_money_enabled',
    ];

    protected $casts = [
        'wave_enabled' => 'boolean',
        'orange_money_enabled' => 'boolean',
    ];

    public static function get(): self
    {
        $row = self::first();
        if (!$row) {
            $row = self::create([
                'wave_enabled' => true,
                'orange_money_enabled' => true,
            ]);
        }
        return $row;
    }
}
