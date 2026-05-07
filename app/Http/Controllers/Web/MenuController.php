<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class MenuController extends Controller
{
    // ========== CATEGORIES ==========
    
    public function categoriesIndex(Request $request)
    {
        $query = Category::withCount('produits')->orderBy('ordre')->orderBy('nom');

        if ($request->filled('search')) {
            $term = $request->string('search')->trim();
            $query->where('nom', 'like', '%'.$term.'%');
        }
        if ($request->filled('statut')) {
            if ($request->input('statut') === 'actif') {
                $query->where('actif', true);
            } elseif ($request->input('statut') === 'inactif') {
                $query->where('actif', false);
            }
        }

        $categories = $query->paginate(10)->withQueryString();

        return view('menu.categories.index', compact('categories'));
    }
    
    public function categoriesCreate()
    {
        return view('menu.categories.create');
    }
    
    public function categoriesStore(Request $request)
    {
        $validated = $request->validate([
            'nom' => 'required|string|max:255|unique:categories,nom',
            'description' => 'nullable|string',
            'ordre' => 'nullable|integer|min:0',
        ]);
        
        $validated['actif'] = $request->has('actif');
        
        Category::create($validated);
        
        return redirect()->route('menu.categories.index')
                        ->with('success', 'Catégorie créée avec succès !');
    }
    
    public function categoriesEdit(Category $category)
    {
        return view('menu.categories.edit', compact('category'));
    }
    
    public function categoriesUpdate(Request $request, Category $category)
    {
        $validated = $request->validate([
            'nom' => ['required', 'string', 'max:255', Rule::unique('categories')->ignore($category->id)],
            'description' => 'nullable|string',
            'ordre' => 'nullable|integer|min:0',
        ]);
        
        $validated['actif'] = $request->has('actif');
        
        $category->update($validated);
        
        return redirect()->route('menu.categories.index')
                        ->with('success', 'Catégorie modifiée avec succès !');
    }
    
    public function categoriesDestroy(Category $category)
    {
        $category->delete();
        return redirect()->route('menu.categories.index')
                        ->with('success', 'Catégorie supprimée avec succès !');
    }
    
    // ========== PRODUCTS ==========
    
    public function productsIndex(Request $request)
    {
        $query = Product::with('categorie')->orderBy('nom');

        if ($request->filled('search')) {
            $term = $request->string('search')->trim();
            $query->where('nom', 'like', '%'.$term.'%');
        }

        if ($request->filled('categorie')) {
            $nomCategorie = $request->string('categorie');
            $query->whereHas('categorie', function ($q) use ($nomCategorie) {
                $q->where('nom', $nomCategorie);
            });
        }

        if ($request->filled('statut')) {
            switch ($request->input('statut')) {
                case 'disponible':
                    $query->where('actif', true)->where('disponible', true);
                    break;
                case 'rupture':
                    $query->where('actif', true)->where('disponible', false);
                    break;
                case 'inactif':
                    $query->where('actif', false);
                    break;
            }
        }

        $products = $query->paginate(10)->withQueryString();
        $categories = Category::where('actif', true)->orderBy('ordre')->get();

        return view('menu.products.index', compact('products', 'categories'));
    }
    
    public function productsCreate()
    {
        $categories = Category::where('actif', true)->get();
        return view('menu.products.create', compact('categories'));
    }
    
    public function productsStore(Request $request)
    {
        $validated = $request->validate([
            'categorie_id' => 'required|exists:categories,id',
            'nom' => 'required|string|max:255',
            'description' => 'nullable|string',
            'prix' => 'required|numeric|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:10240',
        ]);
        
        $validated['disponible'] = $request->has('disponible');
        $validated['actif'] = $request->has('actif');
        
        if ($request->hasFile('image')) {
            $validated['image'] = $request->file('image')->store('produits', 'public');
        }
        
        Product::create($validated);
        
        return redirect()->route('menu.products.index')
                        ->with('success', 'Produit créé avec succès !');
    }
    
    public function productsEdit(Product $product)
    {
        $categories = Category::all();
        return view('menu.products.edit', compact('product', 'categories'));
    }
    
    public function productsUpdate(Request $request, Product $product)
    {
        $validated = $request->validate([
            'categorie_id' => 'required|exists:categories,id',
            'nom' => 'required|string|max:255',
            'description' => 'nullable|string',
            'prix' => 'required|numeric|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:10240',
        ]);
        
        $validated['disponible'] = $request->has('disponible');
        $validated['actif'] = $request->has('actif');
        
        if ($request->hasFile('image')) {
            // Delete old image
            if ($product->image) {
                // Supprimer le préfixe "public/" si présent
                $oldPath = str_starts_with($product->image, 'public/') 
                    ? substr($product->image, 7) 
                    : $product->image;
                Storage::disk('public')->delete($oldPath);
            }
            $validated['image'] = $request->file('image')->store('produits', 'public');
        }
        
        $product->update($validated);
        
        return redirect()->route('menu.products.index')
                        ->with('success', 'Produit modifié avec succès !');
    }
    
    public function productsDestroy(Product $product)
    {
        // Delete image
        if ($product->image) {
            // Supprimer le préfixe "public/" si présent
            $imagePath = str_starts_with($product->image, 'public/') 
                ? substr($product->image, 7) 
                : $product->image;
            Storage::disk('public')->delete($imagePath);
        }
        
        $product->delete();
        
        return redirect()->route('menu.products.index')
                        ->with('success', 'Produit supprimé avec succès !');
    }
    
    public function toggleAvailability(Product $product)
    {
        $product->is_available = !$product->is_available;
        $product->save();
        
        return back()->with('success', 'Disponibilité modifiée avec succès !');
    }
}
