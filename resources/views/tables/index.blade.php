@extends('layouts.app')

@section('title', 'Gestion des Tables')

@section('content')
<div class="row mb-4">
    <div class="col-12">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">📊 Statistiques Tables</h5>
            </div>
            <div class="card-body">
                <div class="row text-center">
                    <div class="col-md-3">
                        <h3 class="text-primary">{{ $stats['total'] }}</h3>
                        <p class="text-muted mb-0">Total</p>
                    </div>
                    <div class="col-md-3">
                        <h3 class="text-success">{{ $stats['libres'] }}</h3>
                        <p class="text-muted mb-0">Libres</p>
                    </div>
                    <div class="col-md-3">
                        <h3 class="text-danger">{{ $stats['occupees'] }}</h3>
                        <p class="text-muted mb-0">Occupées</p>
                    </div>
                    <div class="col-md-3">
                        <h3 class="text-warning">{{ $stats['reservees'] }}</h3>
                        <p class="text-muted mb-0">Réservées</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">🪑 Liste des Tables</h5>
                <a href="{{ route('tables.create') }}" class="btn btn-primary">
                    <i class="bx bx-plus"></i> Nouvelle Table
                </a>
            </div>
            <div class="card-body">
                <form method="get" action="{{ route('tables.index') }}" class="mb-4">
                    <div class="row align-items-end">
                        <div class="col-md-4 mb-3">
                            <label class="form-label small text-muted mb-1">Recherche</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="bx bx-search"></i></span>
                                <input type="text" name="search" class="form-control" placeholder="Rechercher par numéro..." value="{{ request('search') }}">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <label class="form-label small text-muted mb-1">Type</label>
                            <select name="type" class="form-select">
                                <option value="">🏷️ Tous les types</option>
                                <option value="simple" @selected(request('type') === 'simple')>Simple</option>
                                <option value="vip" @selected(request('type') === 'vip')>VIP</option>
                                <option value="espace_jeux" @selected(request('type') === 'espace_jeux')>Espace Jeux</option>
                            </select>
                        </div>
                        <div class="col-md-3 mb-3">
                            <label class="form-label small text-muted mb-1">Statut</label>
                            <select name="statut" class="form-select">
                                <option value="">📊 Tous les statuts</option>
                                <option value="libre" @selected(request('statut') === 'libre')>🟢 Libre</option>
                                <option value="occupee" @selected(request('statut') === 'occupee')>🔴 Occupée</option>
                                <option value="reservee" @selected(request('statut') === 'reservee')>🟡 Réservée</option>
                                <option value="en_paiement" @selected(request('statut') === 'en_paiement')>🔵 En paiement</option>
                            </select>
                        </div>
                        <div class="col-md-2 mb-3 d-flex gap-2">
                            <button type="submit" class="btn btn-primary flex-grow-1"><i class="bx bx-filter-alt"></i> Filtrer</button>
                            <a href="{{ route('tables.index') }}" class="btn btn-outline-secondary" title="Réinitialiser"><i class="bx bx-reset"></i></a>
                        </div>
                    </div>
                </form>

                @if(request()->hasAny(['search', 'type', 'statut']))
                    <div class="alert alert-info mb-3">
                        <i class="bx bx-info-circle"></i> {{ $tables->total() }} table(s) correspondant aux filtres
                    </div>
                @endif

                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Numéro</th>
                                <th>Type</th>
                                <th>Capacité</th>
                                <th>Prix</th>
                                <th>Statut</th>
                                <th class="text-center">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($tables as $table)
                                <tr>
                                    <td><strong class="text-primary">{{ $table->numero }}</strong></td>
                                    <td>
                                        @switch($table->type->value)
                                            @case('simple')
                                                <span class="badge bg-label-secondary">Simple</span>
                                                @break
                                            @case('vip')
                                                <span class="badge bg-label-warning">VIP</span>
                                                @break
                                            @case('espace_jeux')
                                                <span class="badge bg-label-info">Espace Jeux</span>
                                                @break
                                        @endswitch
                                    </td>
                                    <td>{{ $table->capacite }} pers.</td>
                                    <td>
                                        @if($table->prix)
                                            {{ number_format($table->prix, 0, ',', ' ') }} FCFA
                                        @elseif($table->prix_par_heure)
                                            {{ number_format($table->prix_par_heure, 0, ',', ' ') }} FCFA/h
                                        @else
                                            -
                                        @endif
                                    </td>
                                    <td>
                                        @switch($table->statut->value)
                                            @case('libre')
                                                <span class="badge bg-success">Libre</span>
                                                @break
                                            @case('occupee')
                                                <span class="badge bg-danger">Occupée</span>
                                                @break
                                            @case('reservee')
                                                <span class="badge bg-warning">Réservée</span>
                                                @break
                                            @case('en_paiement')
                                                <span class="badge bg-info">En paiement</span>
                                                @break
                                        @endswitch
                                    </td>
                                    <td class="text-center">
                                        <div class="btn-group" role="group">
                                            <a href="{{ route('tables.show', $table) }}" class="btn btn-sm btn-info" title="Voir">
                                                <i class="bx bx-show"></i>
                                            </a>
                                            <a href="{{ route('tables.edit', $table) }}" class="btn btn-sm btn-warning" title="Modifier">
                                                <i class="bx bx-edit"></i>
                                            </a>
                                            <form action="{{ route('tables.destroy', $table) }}" method="POST" style="display:inline;" onsubmit="return confirm('Supprimer cette table ?')">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="btn btn-sm btn-danger" title="Supprimer">
                                                    <i class="bx bx-trash"></i>
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="6" class="text-center text-muted py-4">
                                        Aucune table trouvée.
                                        <a href="{{ route('tables.create') }}">Créez-en une</a>
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-3 mt-3 pt-3 border-top">
                    <div class="text-muted small">
                        @if($tables->total() > 0)
                            Affichage de <strong>{{ $tables->firstItem() }}</strong> à <strong>{{ $tables->lastItem() }}</strong>
                            sur <strong>{{ $tables->total() }}</strong> table(s)
                        @else
                            Aucune table à afficher
                        @endif
                    </div>
                    {{ $tables->links() }}
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
