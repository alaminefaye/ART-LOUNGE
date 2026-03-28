<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Commande;
use App\Models\Product;
use App\Models\Table;
use App\Enums\OrderStatus;
use App\Enums\TableStatus;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\DB;

class CommandeController extends Controller
{
    public function index(Request $request)
    {
        $query = Commande::with(['table', 'user', 'produits']);

        if ($request->filled('search')) {
            $raw = ltrim($request->string('search')->trim(), '#');
            if ($raw !== '' && ctype_digit($raw)) {
                $query->where('id', (int) $raw);
            }
        }
        if ($request->filled('table')) {
            $numero = $request->string('table')->trim();
            $query->whereHas('table', function ($q) use ($numero) {
                $q->where('numero', $numero);
            });
        }
        if ($request->filled('statut')) {
            $query->where('statut', $request->input('statut'));
        }

        $commandes = $query->orderBy('created_at', 'desc')->paginate(10)->withQueryString();
        $tables = Table::orderBy('numero')->get();

        return view('commandes.index', compact('commandes', 'tables'));
    }

    public function create()
    {
        $tables = Table::where('statut', TableStatus::Libre)->get();
        $produits = Product::where('actif', true)
                          ->where('disponible', true)
                          ->with('categorie')
                          ->get();
        $categories = $produits->pluck('categorie')->unique('id');
        
        return view('commandes.create', compact('tables', 'produits', 'categories'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'table_id' => 'required|exists:tables,id',
            'notes' => 'nullable|string',
            'produits' => 'required|array|min:1',
            'produits.*.id' => 'required|exists:produits,id',
            'produits.*.quantite' => 'required|integer|min:1',
            'produits.*.notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated, $request) {
            $table = Table::findOrFail($validated['table_id']);

            // Occupy the table
            if ($table->isLibre()) {
                $table->occuper();
            } elseif ($table->statut === TableStatus::Reservee) {
                $table->occuper();
            }

            $commande = Commande::create([
                'table_id' => $validated['table_id'],
                'user_id' => auth()->id(),
                'notes' => $validated['notes'],
                'statut' => OrderStatus::Attente,
            ]);

            $produitsToAttach = [];
            foreach ($validated['produits'] as $item) {
                $product = Product::findOrFail($item['id']);
                $produitsToAttach[$product->id] = [
                    'quantite' => $item['quantite'],
                    'prix_unitaire' => $product->prix,
                    'notes' => $item['notes'] ?? null,
                ];
            }
            $commande->produits()->attach($produitsToAttach);
            $commande->calculerMontantTotal();

            return redirect()->route('commandes.show', $commande)
                            ->with('success', 'Commande créée avec succès !');
        });
    }

    public function show(Commande $commande)
    {
        $commande->load(['table', 'user', 'produits.categorie']);
        return view('commandes.show', compact('commande'));
    }

    public function edit(Commande $commande)
    {
        if ($commande->statut === OrderStatus::Terminee || $commande->statut === OrderStatus::Annulee) {
            return redirect()->route('commandes.show', $commande)
                            ->with('error', 'Cette commande ne peut plus être modifiée.');
        }

        $commande->load(['table', 'produits']);
        $produits = Product::where('actif', true)
                          ->where('disponible', true)
                          ->with('categorie')
                          ->get();
        $categories = $produits->pluck('categorie')->unique('id');
        
        return view('commandes.edit', compact('commande', 'produits', 'categories'));
    }

    public function update(Request $request, Commande $commande)
    {
        if ($commande->statut === OrderStatus::Terminee || $commande->statut === OrderStatus::Annulee) {
            return redirect()->route('commandes.show', $commande)
                            ->with('error', 'Cette commande ne peut plus être modifiée.');
        }

        $validated = $request->validate([
            'notes' => 'nullable|string',
            'produits' => 'required|array|min:1',
            'produits.*.id' => 'required|exists:produits,id',
            'produits.*.quantite' => 'required|integer|min:1',
            'produits.*.notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated, $commande) {
            $commande->update([
                'notes' => $validated['notes'],
            ]);

            $produitsToSync = [];
            foreach ($validated['produits'] as $item) {
                $product = Product::findOrFail($item['id']);
                $produitsToSync[$product->id] = [
                    'quantite' => $item['quantite'],
                    'prix_unitaire' => $product->prix,
                    'notes' => $item['notes'] ?? null,
                ];
            }
            $commande->produits()->sync($produitsToSync);
            $commande->calculerMontantTotal();

            return redirect()->route('commandes.show', $commande)
                            ->with('success', 'Commande modifiée avec succès !');
        });
    }

    public function updateStatus(Request $request, Commande $commande)
    {
        $validated = $request->validate([
            'statut' => ['required', Rule::enum(OrderStatus::class)],
        ]);

        $commande->update(['statut' => $validated['statut']]);

        // If order is completed, free the table
        if ($commande->statut === OrderStatus::Terminee) {
            $commande->table->liberer();
        }

        return back()->with('success', 'Statut mis à jour avec succès !');
    }

    public function destroy(Commande $commande)
    {
        if ($commande->statut === OrderStatus::Terminee) {
            return back()->with('error', 'Une commande terminée ne peut pas être supprimée.');
        }

        // Free the table if it was occupied only by this order
        if ($commande->table->statut === TableStatus::Occupee) {
            $otherActiveOrders = $commande->table->commandes()
                ->where('id', '!=', $commande->id)
                ->whereNotIn('statut', [OrderStatus::Terminee, OrderStatus::Annulee])
                ->count();
            
            if ($otherActiveOrders === 0) {
                $commande->table->liberer();
            }
        }

        $commande->statut = OrderStatus::Annulee;
        $commande->save();

        return redirect()->route('commandes.index')
                        ->with('success', 'Commande annulée avec succès !');
    }
}
