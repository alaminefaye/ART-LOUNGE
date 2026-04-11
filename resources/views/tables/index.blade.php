@extends('layouts.app')

@section('title', 'Gestion des Tables')

@section('content')
<div class="row mb-4">
    <div class="col-12 d-flex justify-content-between align-items-center">
        <div>
            <h4 class="fw-bold mb-1">🪑 Gestion des Tables</h4>
            <p class="text-muted mb-0">
                {{ $stats['total'] }} tables au total ·
                <span class="text-success fw-semibold">{{ $stats['libres'] }} libres</span> ·
                <span class="text-danger fw-semibold">{{ $stats['occupees'] }} occupées</span> ·
                <span class="text-warning fw-semibold">{{ $stats['reservees'] }} réservées</span>
            </p>
        </div>
        @can('manage_tables')
        <a href="{{ route('tables.create') }}" class="btn btn-primary">
            <i class="bx bx-plus me-1"></i> Nouvelle Table
        </a>
        @endcan
    </div>
</div>

<!-- Filtres -->
<div class="card mb-4">
    <div class="card-body py-3">
        <form method="get" action="{{ route('tables.index') }}" class="row g-3 align-items-end">
            <div class="col-md-4">
                <label class="form-label small">Recherche</label>
                <input type="text" name="search" class="form-control form-control-sm" placeholder="Ex: T5, VIP2..." value="{{ request('search') }}">
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
                    <option value="reservee" @selected(request('statut') === 'reservee')>Réservée</option>
                </select>
            </div>
            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn btn-sm btn-primary flex-grow-1">Filtrer</button>
                <a href="{{ route('tables.index') }}" class="btn btn-sm btn-outline-secondary"><i class="bx bx-reset"></i></a>
            </div>
        </form>
    </div>
</div>

<!-- Grille des tables -->
<div class="row g-3">
    @forelse($tables as $table)
        @php
            $isSubTable = str_contains($table->numero, '.');
            $isVip = $table->type->value === 'vip';

            $statusColor = match($table->statut->value) {
                'libre'       => 'success',
                'occupee'     => 'danger',
                'reservee'    => 'warning',
                'en_paiement' => 'info',
                default       => 'secondary',
            };
            $statusLabel = match($table->statut->value) {
                'libre'       => 'Libre',
                'occupee'     => 'Occupée',
                'reservee'    => 'Réservée',
                'en_paiement' => 'En paiement',
                default       => ucfirst($table->statut->value),
            };
        @endphp

        {{-- Sous-tables : plus petites, légèrement décalées --}}
        @if($isSubTable)
        <div class="col-xl-2 col-lg-2 col-md-3 col-sm-4 col-6">
            <div class="card h-100 border-0 shadow-sm" style="border-left: 3px solid var(--bs-{{ $statusColor }}) !important; opacity: 0.9; border-radius: 8px;">
                <div class="card-body p-2 text-center">
                    <span class="badge bg-label-secondary mb-1" style="font-size:10px;">Sous-table</span>
                    <h5 class="mb-0 fw-bold text-primary" style="font-size:14px;">{{ $table->numero }}</h5>
                    <p class="text-muted mb-1" style="font-size:10px;"><i class="bx bx-user"></i> {{ $table->capacite }} pl.</p>
                    <span class="badge bg-{{ $statusColor }} w-100 py-1" style="font-size:10px;">{{ strtoupper($statusLabel) }}</span>
                    <div class="mt-2 d-flex justify-content-center gap-1">
                        <a href="{{ route('tables.show', $table) }}" class="btn btn-icon btn-xs btn-outline-info" title="Voir"><i class="bx bx-show" style="font-size:12px;"></i></a>
                        @can('manage_tables')
                        <a href="{{ route('tables.edit', $table) }}" class="btn btn-icon btn-xs btn-outline-warning" title="Modifier"><i class="bx bx-edit" style="font-size:12px;"></i></a>
                        @endcan
                    </div>
                </div>
            </div>
        </div>

        {{-- Tables principales --}}
        @else
        <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
            <div class="card h-100 border-0 shadow" style="border-top: 4px solid var(--bs-{{ $isVip ? 'warning' : $statusColor }}) !important; border-radius: 12px;">
                <div class="card-body text-center p-3">
                    <div class="mb-2">
                        @if($isVip)
                            <span class="badge bg-label-warning">⭐ VIP</span>
                        @else
                            <span class="badge bg-label-secondary">Table</span>
                        @endif
                    </div>

                    <h3 class="mb-1 fw-bold {{ $isVip ? 'text-warning' : 'text-primary' }}">{{ $table->numero }}</h3>
                    <p class="text-muted small mb-2"><i class="bx bx-user"></i> {{ $table->capacite }} places</p>

                    <span class="badge bg-{{ $statusColor }} w-100 py-2">{{ strtoupper($statusLabel) }}</span>

                    @if($isVip && $table->prix)
                        <p class="text-muted small mt-1 mb-0">{{ number_format((float) $table->prix, 0, ',', ' ') }} FCFA</p>
                    @endif

                    <div class="mt-3 d-flex justify-content-center gap-1">
                        <a href="{{ route('tables.show', $table) }}" class="btn btn-icon btn-sm btn-outline-info" title="Voir"><i class="bx bx-show"></i></a>
                        @can('manage_tables')
                        <a href="{{ route('tables.edit', $table) }}" class="btn btn-icon btn-sm btn-outline-warning" title="Modifier"><i class="bx bx-edit"></i></a>
                        <form action="{{ route('tables.destroy', $table) }}" method="POST" class="d-inline" onsubmit="return confirm('Supprimer cette table ?')">
                            @csrf @method('DELETE')
                            <button type="submit" class="btn btn-icon btn-sm btn-outline-danger" title="Supprimer"><i class="bx bx-trash"></i></button>
                        </form>
                        @endcan
                    </div>
                </div>
            </div>
        </div>
        @endif

    @empty
        <div class="col-12 text-center py-5">
            <div class="text-muted">Aucune table trouvée.</div>
        </div>
    @endforelse
</div>

<div class="mt-4">
    {{ $tables->links() }}
</div>
@endsection
