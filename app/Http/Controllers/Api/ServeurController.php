<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Serveur;
use Illuminate\Http\Request;

class ServeurController extends Controller
{
    /**
     * Liste des serveurs actifs
     */
    public function index()
    {
        $serveurs = Serveur::where('actif', true)
            ->orderBy('nom')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $serveurs
        ]);
    }
}
