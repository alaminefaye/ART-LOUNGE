<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Avis;
use App\Models\Commande;
use App\Enums\OrderStatus;
use App\Enums\StatutPaiement;
use Illuminate\Http\Request;

class AvisController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $query = Avis::query()->with(['user', 'commande.table']);

        if ($user->hasRole('client')) {
            $query->where('user_id', $user->id);
        }

        $avis = $query->orderByDesc('created_at')->paginate(20);

        $moyenne = (float) (clone $query)->avg('note');
        $total = (int) (clone $query)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'items' => $avis->items(),
                'pagination' => [
                    'current_page' => $avis->currentPage(),
                    'last_page' => $avis->lastPage(),
                    'per_page' => $avis->perPage(),
                    'total' => $avis->total(),
                ],
                'stats' => [
                    'moyenne' => $moyenne,
                    'total' => $total,
                ],
            ],
        ]);
    }

    public function showForCommande(Request $request, int $commandeId)
    {
        $user = $request->user();

        $avis = Avis::query()
            ->where('commande_id', $commandeId)
            ->where('user_id', $user->id)
            ->first();

        if (!$avis) {
            return response()->json([
                'success' => false,
                'message' => 'Aucun avis trouvé.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $avis,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'commande_id' => 'required|integer|exists:commandes,id',
            'note' => 'required|integer|min:1|max:5',
            'commentaire' => 'nullable|string|max:1000',
        ]);

        $user = $request->user();

        $commande = Commande::with(['user', 'table'])->findOrFail($validated['commande_id']);

        if ($user->hasRole('client') && $commande->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'êtes pas autorisé à noter cette commande.',
            ], 403);
        }

        if ($commande->statut !== OrderStatus::Terminee) {
            return response()->json([
                'success' => false,
                'message' => 'Vous pourrez noter après le paiement.',
            ], 409);
        }

        $paiementValide = $commande->paiements()
            ->where('statut', StatutPaiement::Valide)
            ->latest()
            ->first();

        if (!$paiementValide || !$paiementValide->facture) {
            return response()->json([
                'success' => false,
                'message' => 'Facture non disponible pour cette commande.',
            ], 409);
        }

        $exists = Avis::query()
            ->where('commande_id', $commande->id)
            ->where('user_id', $user->id)
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'message' => 'Vous avez déjà noté cette commande.',
            ], 409);
        }

        $avis = Avis::create([
            'user_id' => $user->id,
            'commande_id' => $commande->id,
            'note' => $validated['note'],
            'commentaire' => $validated['commentaire'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Merci pour votre avis !',
            'data' => $avis,
        ], 201);
    }
}

