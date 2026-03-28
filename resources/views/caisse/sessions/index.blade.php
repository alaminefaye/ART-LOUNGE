@extends('layouts.app')

@push('page-css')
<style>
    @media print {
        .no-print { display: none !important; }
    }
</style>
@endpush

@section('content')
<div class="container-fluid py-4">
    <div class="row">
        <div class="col-12">
            <div class="card shadow-sm border-0 mb-4">
                <div class="card-body p-4">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <div>
                            <h2 class="h4 mb-1">Gestion de la Caisse</h2>
                            <p class="text-muted mb-0">Suivi des sessions et bilans journaliers.</p>
                        </div>
                        <div class="text-end">
                            <span class="badge {{ $session_active ? 'bg-success' : 'bg-secondary' }} px-3 py-2">
                                <i class="fas fa-circle me-1 small"></i>
                                {{ $session_active ? 'Session Ouverte' : 'Session Clôturée' }}
                            </span>
                        </div>
                    </div>

                    @if(!$session_active)
                        <div class="alert alert-info border-0 shadow-sm d-flex align-items-center mb-4">
                            <i class="fas fa-info-circle fa-2x me-3 opacity-50"></i>
                            <div>
                                <strong>Prêt à commencer ?</strong>
                                <p class="mb-0">Veuillez ouvrir une session de caisse pour commencer à encaisser des paiements.</p>
                            </div>
                        </div>

                        <div class="card bg-light border-0">
                            <div class="card-body">
                                <form action="{{ route('caisse.sessions.ouvrir') }}" method="POST" class="row g-3">
                                    @csrf
                                    <div class="col-md-6">
                                        <label for="solde_ouverture" class="form-label font-weight-bold">Solde de départ (Fond de caisse)</label>
                                        <div class="input-group">
                                            <input type="number" step="0.01" name="solde_ouverture" id="solde_ouverture" class="form-control form-control-lg" placeholder="0.00" required>
                                            <span class="input-group-text bg-white border-start-0 font-weight-bold">FCFA</span>
                                        </div>
                                    </div>
                                    <div class="col-md-6 d-flex align-items-end">
                                        <button type="submit" class="btn btn-primary btn-lg px-5">
                                            <i class="fas fa-play me-2"></i> Ouvrir la session
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    @else
                        <div class="row g-4">
                            <div class="col-md-4">
                                <div class="card border-0 bg-primary text-white h-100 shadow-sm">
                                    <div class="card-body">
                                        <h6 class="text-white-50 text-uppercase small font-weight-bold mb-3">Fond de caisse initiale</h6>
                                        <h3 class="mb-0">{{ number_format($session_active->solde_ouverture, 0, ',', ' ') }} FCFA</h3>
                                        <small class="text-white-50">Ouverte le {{ $session_active->opened_at->format('d/m/Y à H:i') }}</small>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4 text-center d-flex align-items-center justify-content-center">
                                <div class="d-grid gap-2 w-100 px-3">
                                    <a href="{{ route('caisse.sessions.bilan') }}" class="btn btn-outline-primary btn-lg py-3 border-2">
                                        <i class="fas fa-file-invoice-dollar me-2"></i> Voir le Bilan en temps réel
                                    </a>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="card border-0 bg-dark text-white h-100 shadow-sm">
                                    <div class="card-body">
                                        <h6 class="text-white-50 text-uppercase small font-weight-bold mb-2">Clôturer le service</h6>
                                        <form action="{{ route('caisse.sessions.fermer') }}" method="POST">
                                            @csrf
                                            <div class="mb-3">
                                                <input type="number" step="0.01" name="solde_fermeture_reel" class="form-control bg-transparent border-white text-white" placeholder="Montant réel compté" required>
                                            </div>
                                            <button type="submit" class="btn btn-warning w-100 font-weight-bold" onclick="return confirm('Êtes-vous sûr de vouloir clôturer cette session ?')">
                                                Faire le point & Fermer
                                            </button>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>
                    @endif
                </div>
            </div>
        </div>

        <div class="col-12">
            <div class="card shadow-sm border-0">
                <div class="card-header bg-white py-3 border-0 d-flex flex-wrap justify-content-between align-items-center gap-2">
                    <h5 class="mb-0">Historique des sessions</h5>
                    <small class="text-muted">10 sessions par page</small>
                </div>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="bg-light">
                            <tr>
                                <th class="ps-4 border-0">Date & Heure</th>
                                <th class="border-0 text-center">Ouverture</th>
                                <th class="border-0 text-center">Attendu (Total)</th>
                                <th class="border-0 text-center">Réel (Compté)</th>
                                <th class="border-0 text-center">Écart</th>
                                <th class="border-0 text-center">Statut</th>
                                <th class="pe-4 border-0 text-end no-print" style="width: 1rem;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($historique as $sess)
                                @php
                                    $ecart = $sess->solde_fermeture_reel - $sess->total_attendu;
                                @endphp
                                <tr>
                                    <td class="ps-4">
                                        <div class="d-flex flex-column">
                                            <span class="font-weight-bold">{{ $sess->opened_at->format('d M Y') }}</span>
                                            <small class="text-muted">{{ $sess->opened_at->format('H:i') }} - {{ $sess->closed_at ? $sess->closed_at->format('H:i') : '...' }}</small>
                                        </div>
                                    </td>
                                    <td class="text-center">{{ number_format($sess->solde_ouverture, 0, ',', ' ') }}</td>
                                    <td class="text-center font-weight-bold">{{ number_format($sess->total_attendu, 0, ',', ' ') }}</td>
                                    <td class="text-center font-weight-bold text-primary">{{ number_format($sess->solde_fermeture_reel, 0, ',', ' ') }}</td>
                                    <td class="text-center">
                                        @if($ecart == 0)
                                            <span class="text-success"><i class="fas fa-check-circle me-1"></i> Correct</span>
                                        @elseif($ecart > 0)
                                            <span class="text-info">+{{ number_format($ecart, 0, ',', ' ') }}</span>
                                        @else
                                            <span class="text-danger">{{ number_format($ecart, 0, ',', ' ') }}</span>
                                        @endif
                                    </td>
                                    <td class="text-center">
                                        <span class="badge bg-light text-dark border px-2 py-1">Fermée</span>
                                    </td>
                                    <td class="pe-4 text-end no-print">
                                        <a href="{{ route('caisse.sessions.rapport', $sess) }}" class="btn btn-sm btn-outline-primary" target="_blank" title="Imprimer le rapport">
                                            <i class="fas fa-print"></i>
                                        </a>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="text-center py-5 text-muted">Aucune session clôturée pour le moment.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
                <div class="card-footer bg-white border-0 py-3">
                    @if($historique->hasPages())
                        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2">
                            <small class="text-muted mb-0">
                                Affichage de <strong>{{ $historique->firstItem() }}</strong> à <strong>{{ $historique->lastItem() }}</strong>
                                sur <strong>{{ $historique->total() }}</strong> session(s)
                            </small>
                            {{ $historique->withQueryString()->links() }}
                        </div>
                    @elseif($historique->total() > 0)
                        <small class="text-muted">{{ $historique->total() }} session(s)</small>
                    @endif
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
