@extends('layouts.app')

@push('page-css')
<style>
    @media print {
        .layout-menu, .layout-navbar, .footer, .no-print, .content-backdrop, .navbar-nav-right {
            display: none !important;
        }
        .layout-wrapper, .layout-container, .layout-page, .content-wrapper {
            padding: 0 !important;
            margin: 0 !important;
        }
        body { background: #fff !important; padding: 12mm !important; }
        .card { border: 1px solid #ccc !important; box-shadow: none !important; }
    }
    .print-header { text-align: center; margin-bottom: 1.5rem; padding-bottom: 1rem; border-bottom: 2px solid #333; }
</style>
@endpush

@section('content')
<div class="container-fluid py-4">
    <div class="no-print d-flex align-items-center justify-content-between mb-4 flex-wrap gap-2">
        <a href="{{ route('caisse.sessions.index') }}" class="btn btn-outline-secondary btn-sm">
            <i class="fas fa-arrow-left me-1"></i> Retour à l'historique
        </a>
        <button type="button" class="btn btn-primary" onclick="window.print()">
            <i class="fas fa-print me-1"></i> Imprimer le rapport
        </button>
    </div>

    <div class="print-header">
        <img src="{{ asset('assets/img/logo.png') }}" alt="Logo" style="height: 64px; margin-bottom: 8px;">
        <h1 class="h4 mb-1">Rapport de session de caisse</h1>
        <p class="text-muted small mb-0">{{ config('app.name') }} — Imprimé le {{ now()->format('d/m/Y à H:i') }}</p>
    </div>

    <div class="card shadow-sm border-0 mb-4">
        <div class="card-body">
            <h2 class="h5 text-primary mb-3">Informations session</h2>
            <div class="row g-3 small">
                <div class="col-md-6">
                    <span class="text-muted">Caissier</span>
                    <div class="fw-semibold">{{ $session->user->name }}</div>
                </div>
                <div class="col-md-6">
                    <span class="text-muted">Statut</span>
                    <div><span class="badge bg-secondary">Clôturée</span></div>
                </div>
                <div class="col-md-6">
                    <span class="text-muted">Ouverture</span>
                    <div class="fw-semibold">{{ $session->opened_at->format('d/m/Y à H:i') }}</div>
                </div>
                <div class="col-md-6">
                    <span class="text-muted">Clôture</span>
                    <div class="fw-semibold">{{ $session->closed_at?->format('d/m/Y à H:i') ?? '—' }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="card shadow-sm border-0 mb-4">
        <div class="card-header bg-white border-0 py-3">
            <h3 class="h6 mb-0 text-primary">Encaissements par mode de paiement</h3>
        </div>
        <div class="card-body p-0">
            <ul class="list-group list-group-flush">
                <li class="list-group-item d-flex justify-content-between py-3 px-4">
                    <span><i class="fas fa-money-bill-wave text-success me-2"></i> Espèces</span>
                    <strong>{{ number_format($details['total_especes'], 0, ',', ' ') }} FCFA</strong>
                </li>
                <li class="list-group-item d-flex justify-content-between py-3 px-4">
                    <span><i class="fas fa-mobile-alt text-info me-2"></i> Wave</span>
                    <strong>{{ number_format($details['total_wave'], 0, ',', ' ') }} FCFA</strong>
                </li>
                <li class="list-group-item d-flex justify-content-between py-3 px-4">
                    <span><i class="fas fa-university text-warning me-2"></i> Orange Money</span>
                    <strong>{{ number_format($details['total_orange_money'], 0, ',', ' ') }} FCFA</strong>
                </li>
                <li class="list-group-item d-flex justify-content-between py-3 px-4">
                    <span><i class="fas fa-credit-card text-primary me-2"></i> Carte bancaire</span>
                    <strong>{{ number_format($details['total_carte'], 0, ',', ' ') }} FCFA</strong>
                </li>
                <li class="list-group-item d-flex justify-content-between py-3 px-4">
                    <span><i class="fas fa-star text-secondary me-2"></i> Points fidélité</span>
                    <strong>{{ number_format($details['total_points'], 0, ',', ' ') }} FCFA</strong>
                </li>
            </ul>
            <div class="card-footer bg-light d-flex justify-content-between align-items-center py-3 px-4">
                <span class="fw-bold">Total ventes encaissées</span>
                <span class="h5 mb-0 text-primary">{{ number_format($details['total_ventes'], 0, ',', ' ') }} FCFA</span>
            </div>
        </div>
    </div>

    <div class="card shadow-sm border-0 mb-4" style="border-left: 4px solid #696cff !important;">
        <div class="card-body">
            <h3 class="h6 text-primary mb-3">Synthèse caisse</h3>
            <div class="row g-3">
                <div class="col-md-6">
                    <div class="text-muted small">Fond de caisse à l'ouverture</div>
                    <div class="fs-5 fw-semibold">{{ number_format($session->solde_ouverture, 0, ',', ' ') }} FCFA</div>
                </div>
                <div class="col-md-6">
                    <div class="text-muted small">Total attendu en caisse</div>
                    <div class="fs-5 fw-semibold">{{ number_format($session->total_attendu, 0, ',', ' ') }} FCFA</div>
                </div>
                <div class="col-md-6">
                    <div class="text-muted small">Montant réel compté à la clôture</div>
                    <div class="fs-5 fw-semibold text-primary">{{ number_format($session->solde_fermeture_reel, 0, ',', ' ') }} FCFA</div>
                </div>
                <div class="col-md-6">
                    <div class="text-muted small">Écart</div>
                    <div class="fs-5 fw-semibold">
                        @if(abs($ecart) < 0.01)
                            <span class="text-success"><i class="fas fa-check-circle me-1"></i> Correct (0)</span>
                        @elseif($ecart > 0)
                            <span class="text-info">+{{ number_format($ecart, 0, ',', ' ') }} FCFA</span>
                        @else
                            <span class="text-danger">{{ number_format($ecart, 0, ',', ' ') }} FCFA</span>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
