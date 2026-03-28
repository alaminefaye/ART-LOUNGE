@extends('layouts.app')
@section('title', 'Catégories')
@section('content')
<div class="card">
    <div class="card-header d-flex justify-content-between">
        <h5 class="mb-0">📑 Catégories</h5>
        @can('manage_menu')
        <a href="{{ route('menu.categories.create') }}" class="btn btn-primary"><i class="bx bx-plus"></i> Nouvelle</a>
        @endcan
    </div>
    <div class="card-body">
        <form method="get" action="{{ route('menu.categories.index') }}" class="mb-4">
            <div class="row align-items-end">
                <div class="col-md-8 mb-3">
                    <label class="form-label small text-muted mb-1">Recherche</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bx bx-search"></i></span>
                        <input type="text" name="search" class="form-control" placeholder="Rechercher par nom..." value="{{ request('search') }}">
                    </div>
                </div>
                <div class="col-md-2 mb-3">
                    <label class="form-label small text-muted mb-1">Statut</label>
                    <select name="statut" class="form-select">
                        <option value="">📊 Tous</option>
                        <option value="actif" @selected(request('statut') === 'actif')>✅ Actif</option>
                        <option value="inactif" @selected(request('statut') === 'inactif')>❌ Inactif</option>
                    </select>
                </div>
                <div class="col-md-2 mb-3 d-flex gap-2">
                    <button type="submit" class="btn btn-primary flex-grow-1"><i class="bx bx-filter-alt"></i> Filtrer</button>
                    <a href="{{ route('menu.categories.index') }}" class="btn btn-outline-secondary" title="Réinitialiser"><i class="bx bx-reset"></i></a>
                </div>
            </div>
        </form>

        @if(request()->hasAny(['search', 'statut']))
            <div class="alert alert-info mb-3">
                <i class="bx bx-info-circle"></i> {{ $categories->total() }} catégorie(s) correspondant aux filtres
            </div>
        @endif

        <div class="table-responsive">
            <table class="table table-hover">
                <thead><tr><th>Nom</th><th>Produits</th><th>Ordre</th><th>Statut</th><th>Actions</th></tr></thead>
                <tbody>
                    @forelse($categories as $category)
                    <tr>
                        <td><strong>{{ $category->nom }}</strong></td>
                        <td><span class="badge bg-info">{{ $category->produits_count }}</span></td>
                        <td>{{ $category->ordre }}</td>
                        <td>
                            @if($category->actif)
                                <span class="badge bg-success">Actif</span>
                            @else
                                <span class="badge bg-secondary">Inactif</span>
                            @endif
                        </td>
                        <td>
                            @can('manage_menu')
                            <a href="{{ route('menu.categories.edit', $category) }}" class="btn btn-sm btn-warning"><i class="bx bx-edit"></i></a>
                            <form action="{{ route('menu.categories.destroy', $category) }}" method="POST" style="display:inline;" onsubmit="return confirm('Supprimer ?')">
                                @csrf @method('DELETE')
                                <button type="submit" class="btn btn-sm btn-danger"><i class="bx bx-trash"></i></button>
                            </form>
                            @endcan
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="text-center text-muted">Aucune catégorie trouvée</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-3 mt-3 pt-3 border-top">
            <div class="text-muted small">
                @if($categories->total() > 0)
                    Affichage de <strong>{{ $categories->firstItem() }}</strong> à <strong>{{ $categories->lastItem() }}</strong>
                    sur <strong>{{ $categories->total() }}</strong> catégorie(s)
                @else
                    Aucune catégorie à afficher
                @endif
            </div>
            {{ $categories->links() }}
        </div>
    </div>
</div>
@endsection
