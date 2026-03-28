@extends('layouts.app')

@section('content')
<div class="container-fluid py-4">
    <div class="row">
        <div class="col-12 mb-4">
            <div class="d-flex align-items-center">
                <a href="{{ route('caisse.sessions.index') }}" class="btn btn-outline-secondary btn-sm me-3">
                    <i class="fas fa-arrow-left"></i>
                </a>
                <div>
                    <h2 class="h4 mb-0">Bilan de la session en cours</h2>
                    <p class="text-muted mb-0 small text-uppercase">Ouverte par {{ $session->user->name }} le {{ $session->opened_at->format('d/m/Y à H:i') }}</p>
                </div>
            </div>
        </div>

        <div class="col-md-8">
            <div class="card shadow-sm border-0 mb-4">
                <div class="card-header bg-white py-3 border-0">
                    <h5 class="mb-0 text-primary">Détails par mode de paiement</h5>
                </div>
                <div class="card-body p-0">
                    <ul class="list-group list-group-flush">
                        <li class="list-group-item d-flex justify-content-between align-items-center py-3 px-4">
                            <div>
                                <i class="fas fa-money-bill-wave text-success me-3"></i>
                                <span class="font-weight-bold">Espèces</span>
                            </div>
                            <span class="h5 mb-0">{{ number_format($details['total_especes'], 0, ',', ' ') }} FCFA</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center py-3 px-4">
                            <div>
                                <i class="fas fa-mobile-alt text-info me-3"></i>
                                <span class="font-weight-bold">Wave</span>
                            </div>
                            <span class="h5 mb-0">{{ number_format($details['total_wave'], 0, ',', ' ') }} FCFA</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center py-3 px-4">
                            <div>
                                <i class="fas fa-university text-warning me-3"></i>
                                <span class="font-weight-bold">Orange Money</span>
                            </div>
                            <span class="h5 mb-0">{{ number_format($details['total_orange_money'], 0, ',', ' ') }} FCFA</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center py-3 px-4">
                            <div>
                                <i class="fas fa-credit-card text-primary me-3"></i>
                                <span class="font-weight-bold">Carte Bancaire</span>
                            </div>
                            <span class="h5 mb-0">{{ number_format($details['total_carte'], 0, ',', ' ') }} FCFA</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center py-3 px-4">
                            <div>
                                <i class="fas fa-star text-secondary me-3"></i>
                                <span class="font-weight-bold">Points Fidélité</span>
                            </div>
                            <span class="h5 mb-0">{{ number_format($details['total_points'], 0, ',', ' ') }} FCFA</span>
                        </li>
                    </ul>
                </div>
                <div class="card-footer bg-light py-3 px-4 d-flex justify-content-between align-items-center">
                    <span class="h5 mb-0 font-weight-bold">Total Ventes</span>
                    <span class="h4 mb-0 text-primary font-weight-bold">{{ number_format($details['total_ventes'], 0, ',', ' ') }} FCFA</span>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="card shadow-sm border-0 bg-dark text-white mb-4">
                <div class="card-body p-4">
                    <h5 class="text-white-50 small text-uppercase font-weight-bold mb-4">Récapitulatif Global</h5>
                    
                    <div class="mb-4">
                        <label class="text-white-50 small mb-1">Fond de caisse initiale</label>
                        <div class="h4">{{ number_format($session->solde_ouverture, 0, ',', ' ') }} FCFA</div>
                    </div>

                    <div class="mb-4">
                        <label class="text-white-50 small mb-1">Total Encaissé (Ventes)</label>
                        <div class="h4">+ {{ number_format($details['total_ventes'], 0, ',', ' ') }} FCFA</div>
                    </div>

                    <hr class="border-secondary my-4">

                    <div class="mb-4">
                        <label class="text-warning font-weight-bold small mb-1">TOTAL ATTENDU EN CAISSE</label>
                        <div class="h2 text-warning mb-0">{{ number_format($session->solde_ouverture + $details['total_ventes'], 0, ',', ' ') }} FCFA</div>
                        <small class="text-white-50">Somme à vérifier lors de la clôture.</small>
                    </div>

                    <div class="d-grid gap-2 mt-5">
                        <button type="button" class="btn btn-primary" onclick="window.print()">
                            <i class="fas fa-print me-2"></i> Imprimer le bilan
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
