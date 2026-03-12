<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\PaymentMethodSetting;
use Illuminate\Http\Request;

class PaymentMethodSettingController extends Controller
{
    /**
     * Afficher / éditer les paramètres des moyens de paiement (Wave, Orange Money)
     */
    public function edit()
    {
        $settings = PaymentMethodSetting::get();
        return view('payment-methods.edit', compact('settings'));
    }

    /**
     * Enregistrer les paramètres
     */
    public function update(Request $request)
    {
        $validated = $request->validate([
            'wave_enabled' => 'boolean',
            'orange_money_enabled' => 'boolean',
        ]);

        $settings = PaymentMethodSetting::get();
        $settings->update([
            'wave_enabled' => $request->boolean('wave_enabled'),
            'orange_money_enabled' => $request->boolean('orange_money_enabled'),
        ]);

        return redirect()->route('payment-methods.edit')
            ->with('success', 'Moyens de paiement mis à jour. Les options actives seront visibles dans l\'application mobile.');
    }
}
