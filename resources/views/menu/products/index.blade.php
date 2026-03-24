@extends('layouts.app')
@section('title', 'Produits')
@section('content')
<div class="card">
    <div class="card-header d-flex justify-content-between">
        <h5 class="mb-0">🍽️ Produits</h5>
        <a href="{{ route('menu.products.create') }}" class="btn btn-primary"><i class="bx bx-plus"></i> Nouveau Produit</a>
    </div>
    <div class="card-body">
        <form method="get" action="{{ route('menu.products.index') }}" class="mb-4">
            <div class="row align-items-end">
                <div class="col-md-5 mb-3">
                    <label class="form-label small text-muted mb-1">Recherche</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bx bx-search"></i></span>
                        <input type="text" name="search" class="form-control" placeholder="Rechercher par nom..." value="{{ request('search') }}">
                    </div>
                </div>

                <div class="col-md-3 mb-3">
                    <label class="form-label small text-muted mb-1">Catégorie</label>
                    <select name="categorie" class="form-select">
                        <option value="">📁 Toutes catégories</option>
                        @foreach($categories as $cat)
                            <option value="{{ $cat->nom }}" @selected(request('categorie') === $cat->nom)>{{ $cat->nom }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="col-md-2 mb-3">
                    <label class="form-label small text-muted mb-1">Statut</label>
                    <select name="statut" class="form-select">
                        <option value="">📊 Tous</option>
                        <option value="disponible" @selected(request('statut') === 'disponible')>✅ Disponible</option>
                        <option value="rupture" @selected(request('statut') === 'rupture')>⚠️ Rupture</option>
                        <option value="inactif" @selected(request('statut') === 'inactif')>❌ Inactif</option>
                    </select>
                </div>

                <div class="col-md-2 mb-3 d-flex gap-2">
                    <button type="submit" class="btn btn-primary flex-grow-1">
                        <i class="bx bx-filter-alt"></i> Filtrer
                    </button>
                    <a href="{{ route('menu.products.index') }}" class="btn btn-outline-secondary" title="Réinitialiser les filtres">
                        <i class="bx bx-reset"></i>
                    </a>
                </div>
            </div>
        </form>

        @if(request()->hasAny(['search', 'categorie', 'statut']))
            <div class="alert alert-info mb-3">
                <i class="bx bx-info-circle"></i>
                {{ $products->total() }} produit(s) correspondant aux filtres
            </div>
        @endif

        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Image</th>
                        <th>Nom</th>
                        <th>Catégorie</th>
                        <th>Prix</th>
                        <th>Statut</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($products as $product)
                    <tr>
                        <td>
                            @if($product->image)
                                <img src="{{ $product->image_url }}"
                                     alt="{{ $product->nom }}"
                                     style="width: 50px; height: 50px; object-fit: cover; border-radius: 8px;"
                                     onerror="this.onerror=null; this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                <div style="width: 50px; height: 50px; background: #e9ecef; border-radius: 8px; display: none; align-items: center; justify-content: center;">
                                    <i class="bx bx-image" style="font-size: 24px; color: #adb5bd;"></i>
                                </div>
                            @else
                                <div style="width: 50px; height: 50px; background: #e9ecef; border-radius: 8px; display: flex; align-items: center; justify-content: center;">
                                    <i class="bx bx-image" style="font-size: 24px; color: #adb5bd;"></i>
                                </div>
                            @endif
                        </td>
                        <td><strong>{{ $product->nom }}</strong></td>
                        <td><span class="badge bg-secondary">{{ $product->categorie->nom ?? 'N/A' }}</span></td>
                        <td><strong>{{ number_format($product->prix, 0, ',', ' ') }} FCFA</strong></td>
                        <td>
                            @if($product->actif && $product->disponible)
                                <span class="badge bg-success">Disponible</span>
                            @elseif($product->actif && !$product->disponible)
                                <span class="badge bg-warning">Rupture</span>
                            @else
                                <span class="badge bg-secondary">Inactif</span>
                            @endif
                        </td>
                        <td>
                            <a href="{{ route('menu.products.edit', $product) }}" class="btn btn-sm btn-warning"><i class="bx bx-edit"></i></a>
                            <form action="{{ route('menu.products.destroy', $product) }}" method="POST" style="display:inline;" onsubmit="return confirm('Supprimer ce produit ?')">
                                @csrf @method('DELETE')
                                <button type="submit" class="btn btn-sm btn-danger"><i class="bx bx-trash"></i></button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="text-center text-muted">Aucun produit trouvé</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-3 mt-3 pt-3 border-top">
            <div class="text-muted small">
                @if($products->total() > 0)
                    Affichage de <strong>{{ $products->firstItem() }}</strong> à <strong>{{ $products->lastItem() }}</strong>
                    sur <strong>{{ $products->total() }}</strong> produit(s)
                @else
                    Aucun produit à afficher
                @endif
            </div>
            {{ $products->links() }}
        </div>
    </div>
</div>
@endsection
