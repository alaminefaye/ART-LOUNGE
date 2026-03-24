@extends('layouts.app')

@section('title', 'Avis clients')

@section('content')
<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="h3 mb-0">Avis clients</h1>
    </div>

    <div class="row mb-4">
        <div class="col-md-4 mb-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="text-muted">Moyenne</div>
                    <div class="d-flex align-items-center gap-2">
                        <div class="display-6 mb-0">{{ number_format($moyenne, 1) }}</div>
                        <div class="text-muted">/ 5</div>
                    </div>
                    <div class="text-muted">{{ $total }} avis</div>
                </div>
            </div>
        </div>
        <div class="col-md-8 mb-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="text-muted mb-2">Répartition</div>
                    <div class="row g-2">
                        @for ($i = 5; $i >= 1; $i--)
                            @php $count = $repartition[$i] ?? 0; @endphp
                            <div class="col-12 col-md-6">
                                <div class="d-flex align-items-center justify-content-between">
                                    <div>
                                        @for ($s = 1; $s <= 5; $s++)
                                            <i class="bx {{ $s <= $i ? 'bxs-star text-warning' : 'bx-star text-muted' }}"></i>
                                        @endfor
                                    </div>
                                    <div class="text-muted">{{ $count }}</div>
                                </div>
                            </div>
                        @endfor
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h5 class="card-title mb-0">Liste des avis</h5>
                <form method="GET" class="d-flex align-items-center gap-2">
                    <select name="note" class="form-select form-select-sm" style="width: 140px;">
                        <option value="">Toutes</option>
                        @for ($i = 5; $i >= 1; $i--)
                            <option value="{{ $i }}" @selected(request('note') == (string)$i)>{{ $i }} étoiles</option>
                        @endfor
                    </select>
                    <button class="btn btn-sm btn-primary" type="submit">Filtrer</button>
                </form>
            </div>

            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Client</th>
                            <th>Commande</th>
                            <th>Note</th>
                            <th>Commentaire</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($avis as $a)
                            <tr>
                                <td>{{ $a->created_at->format('d/m/Y H:i') }}</td>
                                <td>{{ $a->user->name ?? '—' }}</td>
                                <td>#{{ $a->commande_id }} {{ $a->commande?->table ? '(Table '.$a->commande->table->numero.')' : '' }}</td>
                                <td>
                                    @for ($s = 1; $s <= 5; $s++)
                                        <i class="bx {{ $s <= $a->note ? 'bxs-star text-warning' : 'bx-star text-muted' }}"></i>
                                    @endfor
                                </td>
                                <td>{{ $a->commentaire ?: '—' }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="text-center text-muted py-4">Aucun avis</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-3 mt-3 pt-3 border-top">
                <div class="text-muted small">
                    @if($avis->total() > 0)
                        Affichage de <strong>{{ $avis->firstItem() }}</strong> à <strong>{{ $avis->lastItem() }}</strong>
                        sur <strong>{{ $avis->total() }}</strong> avis
                    @endif
                </div>
                {{ $avis->links() }}
            </div>
        </div>
    </div>
</div>
@endsection

