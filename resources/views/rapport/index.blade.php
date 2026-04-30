@extends('layouts.app')

@section('title', 'Rapport & bilan')

@section('content')
<div class="row mb-4">
    <div class="col-12 d-flex flex-wrap justify-content-between align-items-center gap-2">
        <div>
            <h4 class="fw-bold mb-1">Rapport & bilan</h4>
            <p class="text-muted mb-0">
                Synthèse financière et activité depuis le {{ $start->format('d/m/Y') }}
            </p>
        </div>
        <form method="get" action="{{ route('rapport.index') }}" class="d-flex align-items-center gap-2">
            <label class="mb-0 text-muted small">Période :</label>
            <select name="periode" class="form-select form-select-sm" style="width: auto;" onchange="this.form.submit()">
                <option value="7" {{ $days === 7 ? 'selected' : '' }}>7 derniers jours</option>
                <option value="30" {{ $days === 30 ? 'selected' : '' }}>30 derniers jours</option>
                <option value="90" {{ $days === 90 ? 'selected' : '' }}>90 derniers jours</option>
            </select>
        </form>
    </div>
</div>

<!-- KPIs -->
<div class="row mb-4">
    <div class="col-sm-6 col-lg-3 mb-3 mb-lg-0">
        <div class="card h-100">
            <div class="card-body">
                <span class="d-block mb-1 text-muted small">Chiffre d'affaires (période)</span>
                <h3 class="mb-0 text-primary">{{ number_format($caTotal, 0, ',', ' ') }} <small class="fs-6 text-muted">FCFA</small></h3>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3 mb-3 mb-lg-0">
        <div class="card h-100">
            <div class="card-body">
                <span class="d-block mb-1 text-muted small">Paiements validés</span>
                <h3 class="mb-0">{{ number_format($nbPaiements, 0, ',', ' ') }}</h3>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3 mb-3 mb-lg-0">
        <div class="card h-100">
            <div class="card-body">
                <span class="d-block mb-1 text-muted small">Panier moyen</span>
                <h3 class="mb-0">{{ number_format($caMoyenParPaiement, 0, ',', ' ') }} <small class="fs-6 text-muted">FCFA</small></h3>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3 mb-3 mb-lg-0">
        <div class="card h-100 border-0">
            <div class="card-body">
                <span class="d-block mb-1 text-muted small">CA mois en cours vs mois précédent</span>
                <h3 class="mb-0">{{ number_format($caMoisEnCours, 0, ',', ' ') }} <small class="fs-6 text-muted">FCFA</small></h3>
                <small class="text-muted">Mois précédent : {{ number_format($caMoisPrecedent, 0, ',', ' ') }} FCFA</small>
                @if($evolutionMoisPct !== null)
                    <div class="mt-1">
                        @if($evolutionMoisPct >= 0)
                            <span class="badge bg-label-success">+{{ number_format($evolutionMoisPct, 1, ',', ' ') }} %</span>
                        @else
                            <span class="badge bg-label-danger">{{ number_format($evolutionMoisPct, 1, ',', ' ') }} %</span>
                        @endif
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>

<div class="row mb-4">
    <!-- Courbe CA -->
    <div class="col-lg-8 mb-4 mb-lg-0">
        <div class="card h-100">
            <div class="card-header">
                <h5 class="card-title mb-0">Évolution du CA (paiements validés)</h5>
                <small class="text-muted">Montants journaliers sur la période sélectionnée</small>
            </div>
            <div class="card-body" style="height: 320px;">
                <canvas id="chartCaJour"></canvas>
            </div>
        </div>
    </div>
    <!-- Moyens de paiement -->
    <div class="col-lg-4 mb-4 mb-lg-0">
        <div class="card h-100">
            <div class="card-header">
                <h5 class="card-title mb-0">Répartition par moyen de paiement</h5>
                <small class="text-muted">Sur la même période</small>
            </div>
            <div class="card-body d-flex align-items-center justify-content-center" style="min-height: 280px;">
                @if(count($dataMoyen) > 0)
                    <canvas id="chartMoyens"></canvas>
                @else
                    <p class="text-muted mb-0">Aucun paiement sur cette période.</p>
                @endif
            </div>
        </div>
    </div>
</div>

<div class="row mb-4">
    <!-- Commandes par statut -->
    <div class="col-lg-4 mb-4 mb-lg-0">
        <div class="card h-100">
            <div class="card-header">
                <h5 class="card-title mb-0">Commandes créées par statut</h5>
                <small class="text-muted">Volume sur la période (toutes commandes)</small>
            </div>
            <div class="card-body" style="height: 300px;">
                @if(count($dataStatut) > 0)
                    <canvas id="chartStatuts"></canvas>
                @else
                    <p class="text-muted">Aucune commande sur cette période.</p>
                @endif
            </div>
        </div>
    </div>
    <!-- Top produits -->
    <div class="col-lg-4 mb-4 mb-lg-0">
        <div class="card h-100">
            <div class="card-header">
                <h5 class="card-title mb-0">Top vendeurs (quantités)</h5>
                <small class="text-muted">Articles vendus sur la période</small>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Produit</th>
                                <th class="text-end">Qté</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($topProduits as $p)
                                <tr>
                                    <td>{{ Str::limit($p->nom, 30) }}</td>
                                    <td class="text-end fw-semibold">{{ number_format($p->quantite, 0, ',', ' ') }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="2" class="text-center text-muted py-4">Aucune vente.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    <!-- Performance Personnel -->
    <div class="col-lg-4">
        <div class="card h-100">
            <div class="card-header">
                <h5 class="card-title mb-0">Performance Personnel</h5>
                <small class="text-muted">Encaissements par membre</small>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Nom</th>
                                <th class="text-end">Trans.</th>
                                <th class="text-end">CA</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($performancePersonnel as $pp)
                                <tr>
                                    <td>{{ $pp->name }}</td>
                                    <td class="text-end">{{ $pp->nb_transactions }}</td>
                                    <td class="text-end fw-semibold text-primary">{{ number_format($pp->total_ca, 0, ',', ' ') }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="3" class="text-center text-muted py-4">Aucun encaissement.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@push('page-js')
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script>
(function () {
    const gold = 'rgb(25, 31, 118)';
    const goldLight = 'rgba(25, 31, 118, 0.15)';

    const labelsJours = @json($labelsJours);
    const dataCaJour = @json($dataCaJour);

    const ctxLine = document.getElementById('chartCaJour');
    if (ctxLine) {
        new Chart(ctxLine, {
            type: 'line',
            data: {
                labels: labelsJours,
                datasets: [{
                    label: 'CA (FCFA)',
                    data: dataCaJour,
                    borderColor: gold,
                    backgroundColor: goldLight,
                    fill: true,
                    tension: 0.3,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: function (v) { return v.toLocaleString('fr-FR'); }
                        }
                    }
                }
            }
        });
    }

    const labelsMoyen = @json($labelsMoyen);
    const dataMoyen = @json($dataMoyen);
    const couleursMoyen = @json($couleursMoyen);
    const ctxDonut = document.getElementById('chartMoyens');
    if (ctxDonut && dataMoyen.length) {
        new Chart(ctxDonut, {
            type: 'doughnut',
            data: {
                labels: labelsMoyen,
                datasets: [{
                    data: dataMoyen,
                    backgroundColor: couleursMoyen,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom' },
                }
            }
        });
    }

    const labelsStatut = @json($labelsStatut);
    const dataStatut = @json($dataStatut);
    const ctxBar = document.getElementById('chartStatuts');
    if (ctxBar && dataStatut.length) {
        new Chart(ctxBar, {
            type: 'bar',
            data: {
                labels: labelsStatut,
                datasets: [{
                    label: 'Commandes',
                    data: dataStatut,
                    backgroundColor: 'rgba(105, 108, 255, 0.7)',
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { beginAtZero: true, ticks: { stepSize: 1 } }
                }
            }
        });
    }
})();
</script>
@endpush
