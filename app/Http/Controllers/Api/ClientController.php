<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\FidelitySetting;
use Illuminate\Http\Request;

class ClientController extends Controller
{
    /**
     * Rechercher un client par téléphone pour la fidélité.
     * GET /api/clients/search?phone=...
     */
    public function search(Request $request)
    {
        $phone = $request->query('phone');
        if (!$phone) {
            return response()->json([
                'success' => false,
                'message' => 'Le numéro de téléphone est requis.',
            ], 400);
        }

        // Nettoyer le téléphone (enlever espaces, etc.)
        $cleanPhone = preg_replace('/\D/', '', $phone);
        
        $client = Client::where('telephone', 'like', '%' . $cleanPhone . '%')
            ->orWhere('telephone', 'like', '%' . $phone . '%')
            ->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client non trouvé.',
            ], 404);
        }

        $settings = FidelitySetting::get();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $client->id,
                'nom_complet' => $client->nom_complet,
                'telephone' => $client->telephone,
                'points_fidelite' => (int) $client->points_fidelite,
                'fidelity_enabled' => (bool) $settings->actif,
                'valeur_fcfa_1_point' => (float) $settings->valeur_fcfa_1_point,
            ],
        ]);
    }
}
