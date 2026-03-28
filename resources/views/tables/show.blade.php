@extends('layouts.app')

@section('title', 'Détails Table ' . $table->numero)

@section('content')
<div class="row">
    <div class="col-md-8">
        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between">
                <h5 class="mb-0">📋 Détails de la Table {{ $table->numero }}</h5>
                <div>
                    @can('manage_tables')
                    <a href="{{ route('tables.edit', $table) }}" class="btn btn-sm btn-warning">
                        <i class="bx bx-edit"></i> Modifier
                    </a>
                    @endcan
                    <a href="{{ route('tables.index') }}" class="btn btn-sm btn-label-secondary">
                        <i class="bx bx-arrow-back"></i> Retour
                    </a>
                </div>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <strong>Numéro :</strong>
                        <p class="text-primary h4">{{ $table->numero }}</p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <strong>Type :</strong>
                        <p>
                            @switch($table->type->value)
                                @case('simple')
                                    <span class="badge bg-secondary">Table Simple</span>
                                    @break
                                @case('vip')
                                    <span class="badge bg-warning">Table VIP</span>
                                    @break
                                @case('espace_jeux')
                                    <span class="badge bg-info">Espace Jeux</span>
                                    @break
                            @endswitch
                        </p>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <strong>Capacité :</strong>
                        <p>{{ $table->capacite }} personnes</p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <strong>Statut Actuel :</strong>
                        <p>
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
                        </p>
                    </div>
                </div>
                
                @if($table->prix || $table->prix_par_heure)
                    <div class="row">
                        @if($table->prix)
                            <div class="col-md-6 mb-3">
                                <strong>Prix Fixe :</strong>
                                <p class="text-success">{{ number_format($table->prix, 0, ',', ' ') }} FCFA</p>
                            </div>
                        @endif
                        @if($table->prix_par_heure)
                            <div class="col-md-6 mb-3">
                                <strong>Prix par Heure :</strong>
                                <p class="text-success">{{ number_format($table->prix_par_heure, 0, ',', ' ') }} FCFA/h</p>
                            </div>
                        @endif
                    </div>
                @endif
            </div>
        </div>
    </div>
    
    <div class="col-md-4">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">QR Code</h5>
                @can('manage_tables')
                <form action="{{ route('tables.regenerate-qr', $table) }}" method="POST" style="display:inline;">
                    @csrf
                    <button type="submit" class="btn btn-sm btn-outline-primary" title="Régénérer QR Code">
                        <i class="bx bx-refresh"></i>
                    </button>
                </form>
                @endcan
            </div>
            <div class="card-body text-center">
                @if($table->qr_code)
                    <img src="{{ $table->qr_code_url }}" alt="QR Code {{ $table->numero }}" class="img-fluid" style="max-width: 250px;">
                    <p class="text-muted mt-2 small">Scannez pour accéder au menu</p>
                    <a href="{{ $table->qr_code_url }}" download="qr-code-{{ $table->numero }}.svg" class="btn btn-sm btn-primary mt-2">
                        <i class="bx bx-download"></i> Télécharger
                    </a>
                @else
                    <p class="text-muted">QR Code non disponible</p>
                    @can('manage_tables')
                    <form action="{{ route('tables.regenerate-qr', $table) }}" method="POST">
                        @csrf
                        <button type="submit" class="btn btn-primary">
                            <i class="bx bx-qr"></i> Générer QR Code
                        </button>
                    </form>
                    @endcan
                @endif
            </div>
        </div>
    </div>
</div>
@endsection

