@extends('layouts.app')

@section('title', 'Gestion des Tables')

@section('content')
<div class="row mb-4">
    <div class="col-12 d-flex justify-content-between align-items-center">
        <div>
            <h4 class="fw-bold mb-1">📊 Gestion des Tables</h4>
            <p class="text-muted mb-0">{{ $stats['total'] }} tables au total ({{ $stats['libres'] }} libres)</p>
        </div>
        <a href="{{ route('tables.create') }}" class="btn btn-primary">
            <i class="bx bx-plus me-1"></i> Nouvelle Table
        </a>
    </div>
</div>

<!-- Filtres -->
<div class="card mb-4">
    <div class="card-body py-3">
        <form method="get" action="{{ route('tables.index') }}" class="row g-3 align-items-end">
            <div class="col-md-4">
                <label class="form-label small">Recherche</label>
                <input type="text" name="search" class="form-control form-control-sm" placeholder="Numéro..." value="{{ request('search') }}">
            </div>
            <div class="col-md-3">
                <label class="form-label small">Type</label>
                <select name="type" class="form-select form-select-sm">
                    <option value="">Tous les types</option>
                    <option value="simple" @selected(request('type') === 'simple')>Simple</option>
                    <option value="vip" @selected(request('type') === 'vip')>VIP</option>
                    <option value="espace_jeux" @selected(request('type') === 'espace_jeux')>Espace Jeux</option>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label small">Statut</label>
                <select name="statut" class="form-select form-select-sm">
                    <option value="">Tous les statuts</option>
                    <option value="libre" @selected(request('statut') === 'libre')>Libre</option>
                    <option value="occupee" @selected(request('statut') === 'occupee')>Occupée</option>
                </select>
            </div>
            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn btn-sm btn-primary flex-grow-1">Filtrer</button>
                <a href="{{ route('tables.index') }}" class="btn btn-sm btn-outline-secondary"><i class="bx bx-reset"></i></a>
            </div>
        </form>
    </div>
</div>

<!-- Grid des Tables (4 par ligne) -->
<div class="row">
    @forelse($tables as $table)
        <div class="col-xl-3 col-lg-3 col-md-4 col-sm-6 mb-4">
            <div class="card h-100 shadow-sm border-0">
                <div class="card-body text-center p-3">
                    <div class="mb-2">
                        @switch($table->type->value)
                            @case('simple') <span class="badge bg-label-secondary">Simple</span> @break
                            @case('vip') <span class="badge bg-label-warning">VIP</span> @break
                            @case('espace_jeux') <span class="badge bg-label-info">Espace Jeux</span> @break
                        @endswitch
                    </div>
                    
                    <h3 class="mb-1 fw-bold text-primary">{{ $table->numero }}</h3>
                    <p class="text-muted small mb-2"><i class="bx bx-user"></i> {{ $table->capacite }} places</p>
                    
                    <div class="mb-3">
                        @switch($table->statut->value)
                            @case('libre') <span class="badge bg-success w-100 py-2">LIBRE</span> @break
                            @case('occupee') <span class="badge bg-danger w-100 py-2">OCCUPÉE</span> @break
                            @case('reservee') <span class="badge bg-warning w-100 py-2">RÉSERVÉE</span> @break
                            @case('en_paiement') <span class="badge bg-info w-100 py-2">EN PAIEMENT</span> @break
                        @endswitch
                    </div>
                    
                    <div class="mt-auto d-flex justify-content-center gap-1">
                        <a href="{{ route('tables.show', $table) }}" class="btn btn-icon btn-sm btn-outline-info" title="Voir"><i class="bx bx-show"></i></a>
                        <a href="{{ route('tables.edit', $table) }}" class="btn btn-icon btn-sm btn-outline-warning" title="Modifier"><i class="bx bx-edit"></i></a>
                        <form action="{{ route('tables.destroy', $table) }}" method="POST" class="d-inline" onsubmit="return confirm('Supprimer cette table ?')">
                            @csrf @method('DELETE')
                            <button type="submit" class="btn btn-icon btn-sm btn-outline-danger" title="Supprimer"><i class="bx bx-trash"></i></button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    @empty
        <div class="col-12 text-center py-5">
            <div class="text-muted">Aucune table trouvée.</div>
        </div>
    @endforelse
</div>

<div class="mt-2">
    {{ $tables->links() }}
</div>
@endsection
