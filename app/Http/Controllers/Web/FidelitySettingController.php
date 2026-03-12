<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\FidelitySetting;
use Illuminate\Http\Request;

class FidelitySettingController extends Controller
{
    /**
     * Afficher / éditer les paramètres de fidélité
     */
    public function edit()
    {
        $settings = FidelitySetting::get();
        return view('fidelity.edit', compact('settings'));
    }

    /**
     * Enregistrer les paramètres
     */
    public function update(Request $request)
    {
        $validated = $request->validate([
            'fcfa_pour_1_point' => 'required|integer|min:1',
            'valeur_fcfa_1_point' => 'required|numeric|min:0.01',
            'actif' => 'boolean',
        ]);

        $settings = FidelitySetting::get();
        $settings->update([
            'fcfa_pour_1_point' => $validated['fcfa_pour_1_point'],
            'valeur_fcfa_1_point' => $validated['valeur_fcfa_1_point'],
            'actif' => $request->boolean('actif'),
        ]);

        return redirect()->route('fidelity.edit')
            ->with('success', 'Paramètres de fidélité enregistrés.');
    }
}
