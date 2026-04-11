<?php

namespace App\Http\Controllers\Web;

use App\Enums\OrderStatus;
use App\Enums\TableStatus;
use App\Http\Controllers\Controller;
use App\Models\Commande;
use App\Models\Product;
use App\Models\Table;
use App\Services\FactureService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class CommandeController extends Controller
{
    protected $factureService;

    public function __construct(FactureService $factureService)
    {
        $this->factureService = $factureService;
    }

    public function index(Request $request)
    {
        $query = Commande::with(['table', 'user', 'produits', 'client']);

        if ($request->filled('search')) {
            $term = $request->string('search')->trim();
            if ($term !== '') {
                $like = '%'.addcslashes($term, '%_\\').'%';
                $query->where(function ($q) use ($term, $like) {
                    $digits = ltrim($term, '#');
                    if ($digits !== '' && ctype_digit($digits)) {
                        $q->where('id', (int) $digits);
                    }
                    $q->orWhereHas('table', function ($t) use ($like) {
                        $t->where('numero', 'like', $like);
                    });
                    $q->orWhereHas('user', function ($u) use ($like) {
                        $u->where('name', 'like', $like);
                    });
                    $q->orWhereHas('client', function ($c) use ($like) {
                        $c->where('nom', 'like', $like)
                            ->orWhere('prenom', 'like', $like)
                            ->orWhere('telephone', 'like', $like);
                    });
                });
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

        return DB::transaction(function () use ($validated) {
            $table = Table::findOrFail($validated['table_id']);

            // Occupy the table
            if ($table->isLibre()) {
                $table->occuper();
            } elseif ($table->statut === TableStatus::Reservee) {
                $table->occuper();
            }

            $commande = Commande::create([
                'table_id' => $validated['table_id'],
                'user_id' => Auth::id(),
                'notes' => $validated['notes'],
                'statut' => OrderStatus::Attente,
            ]);

            // Un produit peut apparaître sur plusieurs lignes (quantités / notes différentes) :
            // ne pas indexer par produit_id, sinon les doublons s'écrasent.
            foreach ($validated['produits'] as $item) {
                $product = Product::findOrFail($item['id']);
                $commande->produits()->attach($product->id, [
                    'quantite' => $item['quantite'],
                    'prix_unitaire' => $product->prix,
                    'notes' => $item['notes'] ?? null,
                ]);
            }
            $commande->calculerMontantTotal();

            return redirect()->route('commandes.show', $commande)
                ->with('success', 'Commande créée avec succès !');
        });
    }

    public function show(Commande $commande)
    {
        $commande->load(['table', 'user.roles', 'user.client', 'client', 'produits.categorie']);

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

            // sync() ne permet qu'une entrée par produit_id ; plusieurs lignes identiques
            // nécessitent plusieurs lignes dans commande_produit (detach puis attach).
            $commande->produits()->detach();
            foreach ($validated['produits'] as $item) {
                $product = Product::findOrFail($item['id']);
                $commande->produits()->attach($product->id, [
                    'quantite' => $item['quantite'],
                    'prix_unitaire' => $product->prix,
                    'notes' => $item['notes'] ?? null,
                ]);
            }
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

        // Free the table when order is terminated OR cancelled, if no other active orders remain
        $newStatut = $commande->fresh()->statut;
        if ($newStatut === OrderStatus::Terminee || $newStatut === OrderStatus::Annulee) {
            /** @var \App\Models\Table|null $table */
            $table = $commande->table()->first();
            if ($table && $table->statut === TableStatus::Occupee) {
                $otherActive = $table->commandes()
                    ->where('id', '!=', $commande->id)
                    ->whereNotIn('statut', [OrderStatus::Terminee, OrderStatus::Annulee])
                    ->count();
                if ($otherActive === 0) {
                    $table->liberer();
                }
            }
        }

        return back()->with('success', 'Statut mis à jour avec succès !');
    }

    public function destroy(Commande $commande)
    {
        if ($commande->statut === OrderStatus::Terminee) {
            return back()->with('error', 'Une commande terminée ne peut pas être supprimée.');
        }

        // Free the table if it was occupied only by this order
        /** @var \App\Models\Table|null $table */
        $table = $commande->table()->first();
        if ($table && $table->statut === TableStatus::Occupee) {
            $otherActiveOrders = $table->commandes()
                ->where('id', '!=', $commande->id)
                ->whereNotIn('statut', [OrderStatus::Terminee, OrderStatus::Annulee])
                ->count();

            if ($otherActiveOrders === 0) {
                $table->liberer();
            }
        }

        $commande->statut = OrderStatus::Annulee;
        $commande->save();

        return redirect()->route('commandes.index')
            ->with('success', 'Commande annulée avec succès !');
    }

    public function printReceipt(Request $request, Commande $commande)
    {
        if ($request->boolean('pdf')) {
            $pdf = $this->factureService->genererPDFThermal($commande);

            return $pdf->stream("recu-commande-80mm-{$commande->id}.pdf");
        }

        $data = $this->factureService->buildThermalTicketData($commande);
        $data['auto_print'] = true;

        return response()->view('factures.thermal', $data);
    }
}
