@extends('layouts.app')

@section('title', 'Dashboard')

<div class="row mb-4">
    <div class="col-12 d-flex justify-content-between align-items-center">
        <h4 class="fw-bold py-3 mb-0"><span class="text-muted fw-light">Accueil /</span> Dashboard</h4>
        <div class="d-flex gap-2">
            <button onclick="window.location.reload()" class="btn btn-primary">
                <i class="bx bx-refresh me-1"></i> Actualiser
            </button>
        </div>
    </div>
</div>

<div class="row">
    <!-- Welcome Card -->
    <div class="col-lg-8 mb-4 order-0">
        <div class="card">
            <div class="d-flex align-items-end row">
                <div class="col-sm-7">
                    <div class="card-body">
                        <h5 class="card-title text-primary">Bienvenue {{ Auth::user()->name }} ! 🎉</h5>
                        <p class="mb-4">
                            Vous avez <span class="fw-bold">{{ $commandesJour }}</span> commandes aujourd'hui.
                            Chiffre d'affaires : <span class="fw-bold">{{ number_format($caJour, 0, ',', ' ') }} FCFA</span>
                        </p>
                        <a href="{{ route('commandes.index') }}" class="btn btn-sm btn-outline-primary">Voir les commandes</a>
                    </div>
                </div>
                <div class="col-sm-5 text-center text-sm-left">
                    <div class="card-body pb-0 px-0 px-md-4">
                        <img src="{{ asset('assets/img/illustrations/man-with-laptop-light.png') }}" height="140" alt="Welcome" />
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Quick Stats -->
    <div class="col-lg-4 col-md-4 order-1">
        <div class="row">
            <div class="col-lg-6 col-md-12 col-6 mb-4">
                <div class="card">
                    <div class="card-body">
                        <span class="fw-semibold d-block mb-1">Tables Occupées</span>
                        <h3 class="card-title mb-2">{{ $tablesOccupees }}/{{ $tablesTotal }}</h3>
                        <small class="text-success fw-semibold">
                            <i class="bx bx-check-circle"></i> {{ $tablesLibres }} libres
                        </small>
                    </div>
                </div>
            </div>
            <div class="col-lg-6 col-md-12 col-6 mb-4">
                <div class="card">
                    <div class="card-body">
                        <span class="fw-semibold d-block mb-1">Commandes</span>
                        <h3 class="card-title text-nowrap mb-1">{{ $commandesJour }}</h3>
                        <small class="text-warning fw-semibold">
                            <i class="bx bx-time"></i> {{ $commandesEnCours }} en cours
                        </small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <!-- CA Today & Week -->
    <div class="col-md-6 col-lg-4 mb-4">
        <div class="card h-100">
            <div class="card-header d-flex align-items-center justify-content-between pb-0">
                <div class="card-title mb-0">
                    <h5 class="m-0 me-2">Chiffre d'Affaires</h5>
                    <small class="text-muted">Aujourd'hui</small>
                </div>
            </div>
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <div class="d-flex flex-column align-items-center gap-1">
                        <h2 class="mb-2">{{ number_format($caJour, 0, ',', ' ') }}</h2>
                        <span>FCFA</span>
                    </div>
                </div>
                <hr>
                <div class="text-muted">
                    <div class="d-flex justify-content-between">
                        <span>Cette semaine :</span>
                        <span class="fw-bold">{{ number_format($caSemaine, 0, ',', ' ') }} FCFA</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Produits Populaires -->
    <div class="col-md-6 col-lg-4 mb-4">
        <div class="card h-100">
            <div class="card-header d-flex align-items-center justify-content-between">
                <h5 class="card-title m-0 me-2">Produits Populaires</h5>
                <small class="text-muted">Aujourd'hui</small>
            </div>
            <div class="card-body">
                <ul class="p-0 m-0">
                    @forelse($produitsPopulaires as $produit)
                        <li class="d-flex mb-3 pb-1">
                            <div class="avatar flex-shrink-0 me-3">
                                <span class="avatar-initial rounded bg-label-primary">
                                    <i class="bx bx-food-menu"></i>
                                </span>
                            </div>
                            <div class="d-flex w-100 flex-wrap align-items-center justify-content-between gap-2">
                                <div class="me-2">
                                    <h6 class="mb-0">{{ $produit->name }}</h6>
                                    <small class="text-muted">{{ $produit->total_quantite }} vendus</small>
                                </div>
                            </div>
                        </li>
                    @empty
                        <li class="text-center text-muted py-3">Aucune vente aujourd'hui</li>
                    @endforelse
                </ul>
            </div>
        </div>
    </div>
    
    <!-- Dernières Commandes -->
    <div class="col-md-6 col-lg-4 mb-4">
        <div class="card h-100">
            <div class="card-header d-flex align-items-center justify-content-between">
                <h5 class="card-title m-0 me-2">Dernières Commandes</h5>
            </div>
            <div class="card-body">
                <ul class="p-0 m-0">
                    @forelse($dernieresCommandes as $commande)
                        <li class="d-flex mb-3 pb-1">
                            <div class="avatar flex-shrink-0 me-3">
                                <span class="avatar-initial rounded bg-label-info">
                                    {{ $commande->table->numero }}
                                </span>
                            </div>
                            <div class="d-flex w-100 flex-wrap align-items-center justify-content-between gap-2">
                                <div class="me-2">
                                    <h6 class="mb-0">{{ $commande->table->numero }}</h6>
                                    <small class="text-muted">{{ $commande->created_at->diffForHumans() }}</small>
                                </div>
                                <div class="user-progress">
                                    @switch($commande->statut->value)
                                        @case('attente')
                                            <span class="badge bg-warning">En attente</span>
                                            @break
                                        @case('preparation')
                                            <span class="badge bg-info">Préparation</span>
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
                                </div>
                            </div>
                        </li>
                    @empty
                        <li class="text-center text-muted py-3">Aucune commande</li>
                    @endforelse
                </ul>
            </div>
        </div>
    </div>
</div>

<!-- Quick Actions -->
<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-header">
                <h5 class="card-title mb-0">Actions Rapides</h5>
            </div>
            <div class="card-body">
                <div class="row text-center">
                    <div class="col-md-3 col-6 mb-3">
                        <a href="{{ route('tables.index') }}" class="btn btn-outline-primary w-100 p-3">
                            <i class="bx bx-grid-alt mb-1 d-block" style="font-size: 1.5rem;"></i>
                            <span class="small">Tables</span>
                        </a>
                    </div>
                    <div class="col-md-3 col-6 mb-3">
                        <a href="{{ route('commandes.create') }}" class="btn btn-outline-success w-100 p-3">
                            <i class="bx bx-plus-circle mb-1 d-block" style="font-size: 1.5rem;"></i>
                            <span class="small">Commande</span>
                        </a>
                    </div>
                    <div class="col-md-3 col-6 mb-3">
                        <a href="{{ route('caisse.index') }}" class="btn btn-outline-warning w-100 p-3">
                            <i class="bx bx-dollar-circle mb-1 d-block" style="font-size: 1.5rem;"></i>
                            <span class="small">Caisse</span>
                        </a>
                    </div>
                    <div class="col-md-3 col-6 mb-3">
                        <a href="{{ route('menu.products.index') }}" class="btn btn-outline-info w-100 p-3">
                            <i class="bx bx-food-menu mb-1 d-block" style="font-size: 1.5rem;"></i>
                            <span class="small">Menu</span>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
