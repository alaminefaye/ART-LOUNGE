<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ProductController extends Controller
{
    /**
     * Liste des produits
     * GET /api/produits
     */
    public function index(Request $request)
    {
        $query = Product::with('categorie')
            ->actifs();

        // Filtres
        if ($request->has('categorie_id')) {
            $query->ofCategorie($request->categorie_id);
        }

        if ($request->has('disponible')) {
            $query->where('disponible', $request->boolean('disponible'));
        }

        $produits = $query->orderBy('nom')->get();

        return response()->json([
            'success' => true,
            'data' => $produits->map(fn($p) => $this->formatProduct($p)),
        ]);
    }

    /**
     * Créer un produit
     * POST /api/produits
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'categorie_id' => 'required|exists:categories,id',
            'nom' => 'required|string|max:255',
            'description' => 'nullable|string',
            'prix' => 'required|numeric|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:10240',
            'disponible' => 'boolean',
            'actif' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        $data = $validator->validated();

        // Upload de l'image
        if ($request->hasFile('image')) {
            $data['image'] = $this->uploadImage($request->file('image'));
        }

        $produit = Product::create($data);

        return response()->json([
            'success' => true,
            'message' => 'Produit créé avec succès',
            'data' => $this->formatProduct($produit->load('categorie')),
        ], 201);
    }

    /**
     * Afficher un produit
     * GET /api/produits/{id}
     */
    public function show($id)
    {
        $produit = Product::with('categorie')->find($id);

        if (!$produit) {
            return response()->json([
                'success' => false,
                'message' => 'Produit non trouvé',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatProduct($produit),
        ]);
    }

    /**
     * Note moyenne d'un produit (basée sur les avis des commandes qui contiennent ce produit).
     * GET /api/produits/{id}/rating
     */
    public function rating(int $id)
    {
        $exists = Product::query()->whereKey($id)->exists();
        if (!$exists) {
            return response()->json([
                'success' => false,
                'message' => 'Produit non trouvé',
            ], 404);
        }

        $stats = DB::table('avis')
            ->join('commande_produit', 'commande_produit.commande_id', '=', 'avis.commande_id')
            ->where('commande_produit.produit_id', $id)
            ->selectRaw('AVG(avis.note) as moyenne, COUNT(*) as total')
            ->first();

        $moyenne = $stats?->moyenne !== null ? (float) $stats->moyenne : 0.0;
        $total = $stats?->total !== null ? (int) $stats->total : 0;

        return response()->json([
            'success' => true,
            'data' => [
                'moyenne' => $moyenne,
                'total' => $total,
            ],
        ]);
    }

    /**
     * Mettre à jour un produit
     * PUT/PATCH /api/produits/{id}
     */
    public function update(Request $request, $id)
    {
        $produit = Product::find($id);

        if (!$produit) {
            return response()->json([
                'success' => false,
                'message' => 'Produit non trouvé',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'categorie_id' => 'sometimes|exists:categories,id',
            'nom' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'prix' => 'sometimes|numeric|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:10240',
            'disponible' => 'boolean',
            'actif' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        $data = $validator->validated();

        // Upload nouvelle image
        if ($request->hasFile('image')) {
            // Supprimer ancienne image
            if ($produit->image) {
                Storage::disk('public')->delete($produit->image);
            }
            $data['image'] = $this->uploadImage($request->file('image'));
        }

        $produit->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Produit mis à jour avec succès',
            'data' => $this->formatProduct($produit->fresh()->load('categorie')),
        ]);
    }

    /**
     * Supprimer un produit
     * DELETE /api/produits/{id}
     */
    public function destroy($id)
    {
        $produit = Product::find($id);

        if (!$produit) {
            return response()->json([
                'success' => false,
                'message' => 'Produit non trouvé',
            ], 404);
        }

        // Supprimer l'image
        if ($produit->image) {
            Storage::disk('public')->delete($produit->image);
        }

        $produit->delete();

        return response()->json([
            'success' => true,
            'message' => 'Produit supprimé avec succès',
        ]);
    }

    /**
     * Upload d'une image
     */
    private function uploadImage($file): string
    {
        $filename = time() . '_' . uniqid() . '.' . $file->extension();
        $path = $file->storeAs('produits', $filename, 'public');
        return $path;
    }

    /**
     * Formater un produit pour la réponse
     */
    private function formatProduct(Product $produit): array
    {
        return [
            'id' => $produit->id,
            'categorie_id' => $produit->categorie_id,
            'categorie' => $produit->categorie ? [
                'id' => $produit->categorie->id,
                'nom' => $produit->categorie->nom,
            ] : null,
            'nom' => $produit->nom,
            'description' => $produit->description,
            'prix' => $produit->prix,
            'image' => $produit->image,
            'image_url' => $produit->image_url,
            'disponible' => $produit->disponible,
            'actif' => $produit->actif,
            'created_at' => $produit->created_at,
            'updated_at' => $produit->updated_at,
        ];
    }
}
