@extends('layouts.app')
@section('title', 'Commandes')
@section('content')
<div class="card">
    <div class="card-header d-flex justify-content-between">
        <h5 class="mb-0">📝 Commandes</h5>
        <a href="{{ route('commandes.create') }}" class="btn btn-primary"><i class="bx bx-plus"></i> Nouvelle Commande</a>
    </div>
    <div class="card-body">
        <form method="get" action="{{ route('commandes.index') }}" class="mb-4">
            <div class="row align-items-end">
                <div class="col-md-3 mb-3">
                    <label class="form-label small text-muted mb-1">ID commande</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bx bx-search"></i></span>
                        <input type="text" name="search" class="form-control" placeholder="#ID..." value="{{ request('search') }}">
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <label class="form-label small text-muted mb-1">Table</label>
                    <select name="table" class="form-select">
                        <option value="">🪑 Toutes les tables</option>
                        @foreach($tables as $tbl)
                            <option value="{{ $tbl->numero }}" @selected(request('table') === $tbl->numero)>Table {{ $tbl->numero }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-3 mb-3">
                    <label class="form-label small text-muted mb-1">Statut</label>
                    <select name="statut" class="form-select">
                        <option value="">📊 Tous statuts</option>
                        <option value="attente" @selected(request('statut') === 'attente')>⏳ En attente</option>
                        <option value="preparation" @selected(request('statut') === 'preparation')>🔄 En préparation</option>
                        <option value="servie" @selected(request('statut') === 'servie')>🍽️ Servie</option>
                        <option value="terminee" @selected(request('statut') === 'terminee')>✅ Terminée</option>
                        <option value="annulee" @selected(request('statut') === 'annulee')>❌ Annulée</option>
                    </select>
                </div>
                <div class="col-md-3 mb-3 d-flex gap-2">
                    <button type="submit" class="btn btn-primary flex-grow-1"><i class="bx bx-filter-alt"></i> Filtrer</button>
                    <a href="{{ route('commandes.index') }}" class="btn btn-outline-secondary" title="Réinitialiser"><i class="bx bx-reset"></i></a>
                </div>
            </div>
        </form>

        @if(request()->hasAny(['search', 'table', 'statut']))
            <div class="alert alert-info mb-3">
                <i class="bx bx-info-circle"></i> {{ $commandes->total() }} commande(s) correspondant aux filtres
            </div>
        @endif

        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Table</th>
                        <th>Serveur</th>
                        <th>Articles</th>
                        <th>Montant</th>
                        <th>Statut</th>
                        <th>Date</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($commandes as $commande)
                    <tr>
                        <td><strong>#{{ $commande->id }}</strong></td>
                        <td><span class="badge bg-primary">{{ $commande->table->numero }}</span></td>
                        <td>{{ $commande->user->name ?? 'N/A' }}</td>
                        <td>{{ $commande->produits->count() }} article(s)</td>
                        <td><strong>{{ number_format($commande->montant_total, 0, ',', ' ') }} FCFA</strong></td>
                        <td>
                            @switch($commande->statut->value)
                                @case('attente')
                                    <span class="badge bg-warning">En attente</span>
                                    @break
                                @case('preparation')
                                    <span class="badge bg-info">En préparation</span>
                                    @break
                                @case('servie')
                                    <span class="badge bg-primary">Servie</span>
                                    @break
                                @case('terminee')
                                    <span class="badge bg-success">Terminée</span>
                                    @break
                                @case('annulee')
                                    <span class="badge bg-danger">Annulée</span>
                                    @break
                            @endswitch
                        </td>
                        <td>{{ $commande->created_at->format('d/m/Y H:i') }}</td>
                        <td>
                            <a href="{{ route('commandes.show', $commande) }}" class="btn btn-sm btn-info" title="Voir"><i class="bx bx-show"></i></a>
                            @if($commande->statut->value !== 'terminee' && $commande->statut->value !== 'annulee')
                                <a href="{{ route('commandes.edit', $commande) }}" class="btn btn-sm btn-warning" title="Modifier"><i class="bx bx-edit"></i></a>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="8" class="text-center text-muted">Aucune commande trouvée</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-3 mt-3 pt-3 border-top">
            <div class="text-muted small">
                @if($commandes->total() > 0)
                    Affichage de <strong>{{ $commandes->firstItem() }}</strong> à <strong>{{ $commandes->lastItem() }}</strong>
                    sur <strong>{{ $commandes->total() }}</strong> commande(s)
                @else
                    Aucune commande à afficher
                @endif
            </div>
            {{ $commandes->links() }}
        </div>
    </div>
</div>
@endsection
