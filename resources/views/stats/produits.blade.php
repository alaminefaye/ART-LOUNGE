@extends('layouts.app')
@section('title', 'Statistiques Produits')

@section('content')
{{-- ═══════════════════════  HEADER  ════════════════════════════════ --}}
<div class="row mb-4">
    <div class="col-12 d-flex flex-wrap justify-content-between align-items-center gap-2">
        <div>
            <h4 class="fw-bold mb-1">📊 Statistiques Produits</h4>
            <p class="text-muted mb-0">
                Analyse des ventes du {{ $start->format('d/m/Y') }} à aujourd'hui
            </p>
        </div>
        <form method="get" action="{{ route('stats.produits') }}" class="d-flex align-items-center gap-2">
            <label class="mb-0 text-muted small">Période :</label>
            <select name="periode" class="form-select form-select-sm" style="width:auto;" onchange="this.form.submit()">
                <option value="7"   {{ $days === 7   ? 'selected' : '' }}>7 jours</option>
                <option value="30"  {{ $days === 30  ? 'selected' : '' }}>30 jours</option>
                <option value="90"  {{ $days === 90  ? 'selected' : '' }}>90 jours</option>
                <option value="365" {{ $days === 365 ? 'selected' : '' }}>1 an</option>
            </select>
        </form>
    </div>
</div>

{{-- ═══════════════════════  KPIs  ══════════════════════════════════ --}}
<div class="row mb-4">
    <div class="col-sm-6 col-lg-3 mb-3">
        <div class="card h-100">
            <div class="card-body">
                <span class="d-block mb-1 text-muted small">Articles vendus</span>
                <h3 class="mb-0 text-primary">{{ number_format($totalArticles, 0, ',', ' ') }}</h3>
                <small class="text-muted">Toutes catégories</small>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3 mb-3">
        <div class="card h-100">
            <div class="card-body">
                <span class="d-block mb-1 text-muted small">CA produits estimé</span>
                <h3 class="mb-0 text-success">{{ number_format($totalRevenus, 0, ',', ' ') }} <small class="fs-6">FCFA</small></h3>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3 mb-3">
        <div class="card h-100">
            <div class="card-body">
                <span class="d-block mb-1 text-muted small">Produits vendus</span>
                <h3 class="mb-0">{{ $nbProduits }}</h3>
                <small class="text-muted">Références différentes</small>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3 mb-3">
        <div class="card h-100">
            <div class="card-body">
                <span class="d-block mb-1 text-muted small">Meilleure vente</span>
                @if($topParQuantite->isNotEmpty())
                    <h5 class="mb-0 fw-bold text-warning">{{ Str::limit($topParQuantite->first()->nom, 20) }}</h5>
                    <small class="text-muted">{{ number_format($topParQuantite->first()->quantite, 0, ',', ' ') }} pièces</small>
                @else
                    <p class="text-muted mb-0">—</p>
                @endif
            </div>
        </div>
    </div>
</div>

{{-- ═══════════════════════  CHARTS ROW 1  ═════════════════════════ --}}
<div class="row mb-4">
    {{-- Top 10 par quantité - horizontal bar --}}
    <div class="col-lg-7 mb-4 mb-lg-0">
        <div class="card h-100">
            <div class="card-header">
                <h5 class="card-title mb-0">🏆 Top produits — quantités vendues</h5>
                <small class="text-muted">Les 15 produits les plus commandés sur la période</small>
            </div>
            <div class="card-body" style="height:380px;">
                @if($topParQuantite->isEmpty())
                    <p class="text-muted mt-3">Aucune vente sur cette période.</p>
                @else
                    <canvas id="chartTopQte"></canvas>
                @endif
            </div>
        </div>
    </div>

    {{-- Donut catégories --}}
    <div class="col-lg-5 mb-4 mb-lg-0">
        <div class="card h-100">
            <div class="card-header">
                <h5 class="card-title mb-0">🗂️ Ventes par catégorie</h5>
                <small class="text-muted">Répartition du CA estimé</small>
            </div>
            <div class="card-body d-flex align-items-center justify-content-center" style="min-height:320px;">
                @if($parCategorie->isEmpty())
                    <p class="text-muted">Aucune donnée.</p>
                @else
                    <canvas id="chartCategories"></canvas>
                @endif
            </div>
        </div>
    </div>
</div>

{{-- ═══════════════════════  CHARTS ROW 2  ═════════════════════════ --}}
<div class="row mb-4">
    {{-- Top par revenu --}}
    <div class="col-lg-6 mb-4 mb-lg-0">
        <div class="card h-100">
            <div class="card-header">
                <h5 class="card-title mb-0">💰 Top 10 — CA généré par produit</h5>
                <small class="text-muted">Qté × prix unitaire</small>
            </div>
            <div class="card-body" style="height:300px;">
                @if($topParRevenu->isEmpty())
                    <p class="text-muted mt-3">Aucune donnée.</p>
                @else
                    <canvas id="chartTopRevenu"></canvas>
                @endif
            </div>
        </div>
    </div>

    {{-- Ventes par heure --}}
    <div class="col-lg-6 mb-4 mb-lg-0">
        <div class="card h-100">
            <div class="card-header">
                <h5 class="card-title mb-0">🕐 Activité par heure</h5>
                <small class="text-muted">À quelle heure vend-on le plus ?</small>
            </div>
            <div class="card-body" style="height:300px;">
                <canvas id="chartHeures"></canvas>
            </div>
        </div>
    </div>
</div>

{{-- ═══════════════════════  TABLE COMPLÈTE  ════════════════════════ --}}
<div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
        <div>
            <h5 class="card-title mb-0">📋 Détail complet par produit</h5>
            <small class="text-muted">Tous les produits vendus sur la période</small>
        </div>
        <input type="text" id="tableSearch" class="form-control form-control-sm" style="width:220px;" placeholder="Rechercher un produit...">
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover mb-0" id="produitsTable">
                <thead class="table-light">
                    <tr>
                        <th style="width:40px;">#</th>
                        <th>Produit</th>
                        <th>Catégorie</th>
                        <th class="text-end">Qté vendue</th>
                        <th class="text-end">CA estimé (FCFA)</th>
                        <th style="width:140px;">Part des ventes</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($tousProduits as $i => $p)
                    @php
                        $pct = round(($p->quantite / $grandTotalQte) * 100, 1);
                        $barColor = match(true) {
                            $i === 0 => '#191f76',
                            $i === 1 => '#8592a3',
                            $i === 2 => '#c0733a',
                            $pct >= 10 => '#696cff',
                            default   => '#03c3ec',
                        };
                    @endphp
                    <tr>
                        <td>
                            @if($i === 0) 🥇
                            @elseif($i === 1) 🥈
                            @elseif($i === 2) 🥉
                            @else <span class="text-muted">{{ $i + 1 }}</span>
                            @endif
                        </td>
                        <td class="fw-semibold">{{ $p->nom }}</td>
                        <td><span class="badge bg-label-secondary">{{ $p->categorie }}</span></td>
                        <td class="text-end">{{ number_format($p->quantite, 0, ',', ' ') }}</td>
                        <td class="text-end text-primary fw-semibold">{{ number_format($p->revenus, 0, ',', ' ') }}</td>
                        <td>
                            <div class="d-flex align-items-center gap-2">
                                <div class="progress flex-grow-1" style="height:6px;">
                                    <div class="progress-bar" style="width:{{ $pct }}%; background:{{ $barColor }};"></div>
                                </div>
                                <small class="text-muted" style="width:38px;">{{ $pct }}%</small>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="text-center text-muted py-5">
                            <i class="bx bx-package fs-1 d-block mb-2"></i>
                            Aucune vente enregistrée sur cette période.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection

@push('page-js')
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script>
(function () {
    const gold      = 'rgb(25,31,118)';
    const goldLight = 'rgba(25,31,118,0.15)';
    const palette   = ['#191f76','#696cff','#03c3ec','#71dd37','#ffab00','#ff3e1d','#8592a3','#20c997','#fd7e14','#6610f2'];

    // ── Top par quantité ─────────────────────────────────────────────
    const labelsQte = @json($topParQuantite->pluck('nom'));
    const dataQte   = @json($topParQuantite->pluck('quantite'));

    const ctxQte = document.getElementById('chartTopQte');
    if (ctxQte) {
        new Chart(ctxQte, {
            type: 'bar',
            data: {
                labels: labelsQte,
                datasets: [{
                    label: 'Quantité',
                    data: dataQte,
                    backgroundColor: labelsQte.map((_, i) => palette[i % palette.length] + 'cc'),
                    borderColor:     labelsQte.map((_, i) => palette[i % palette.length]),
                    borderWidth: 1,
                    borderRadius: 4,
                }]
            },
            options: {
                indexAxis: 'y',
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    x: { beginAtZero: true, ticks: { callback: v => v.toLocaleString('fr-FR') } },
                    y: { ticks: { font: { size: 11 } } }
                }
            }
        });
    }

    // ── Donut catégories ─────────────────────────────────────────────
    const labelsCat = @json($parCategorie->pluck('categorie'));
    const dataCat   = @json($parCategorie->pluck('revenus'));

    const ctxCat = document.getElementById('chartCategories');
    if (ctxCat && dataCat.length) {
        new Chart(ctxCat, {
            type: 'doughnut',
            data: {
                labels: labelsCat,
                datasets: [{
                    data: dataCat,
                    backgroundColor: palette.slice(0, labelsCat.length),
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom', labels: { font: { size: 12 } } },
                    tooltip: {
                        callbacks: {
                            label: ctx => ' ' + ctx.label + ': ' + ctx.parsed.toLocaleString('fr-FR') + ' FCFA'
                        }
                    }
                }
            }
        });
    }

    // ── Top par revenu ───────────────────────────────────────────────
    const labelsRev = @json($topParRevenu->pluck('nom'));
    const dataRev   = @json($topParRevenu->pluck('revenus'));

    const ctxRev = document.getElementById('chartTopRevenu');
    if (ctxRev) {
        new Chart(ctxRev, {
            type: 'bar',
            data: {
                labels: labelsRev,
                datasets: [{
                    label: 'CA (FCFA)',
                    data: dataRev,
                    backgroundColor: palette.map(c => c + 'bb'),
                    borderColor: palette,
                    borderWidth: 1,
                    borderRadius: 4,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { beginAtZero: true, ticks: { callback: v => (v/1000).toLocaleString('fr-FR') + 'k' } },
                    x: { ticks: { font: { size: 10 }, maxRotation: 30 } }
                }
            }
        });
    }

    // ── Ventes par heure ─────────────────────────────────────────────
    const labelsH = @json($labelsHeures);
    const dataH   = @json($dataHeures);

    const ctxH = document.getElementById('chartHeures');
    if (ctxH) {
        new Chart(ctxH, {
            type: 'bar',
            data: {
                labels: labelsH,
                datasets: [{
                    label: 'Articles',
                    data: dataH,
                    backgroundColor: dataH.map(v => {
                        const max = Math.max(...dataH, 1);
                        const alpha = 0.3 + (v / max) * 0.7;
                        return `rgba(208,160,48,${alpha.toFixed(2)})`;
                    }),
                    borderRadius: 3,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { beginAtZero: true, ticks: { stepSize: 1 } },
                    x: { ticks: { font: { size: 10 } } }
                }
            }
        });
    }

    // ── Recherche dans le tableau ─────────────────────────────────────
    const searchInput = document.getElementById('tableSearch');
    if (searchInput) {
        searchInput.addEventListener('input', function () {
            const term = this.value.toLowerCase();
            document.querySelectorAll('#produitsTable tbody tr').forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(term) ? '' : 'none';
            });
        });
    }
})();
</script>
@endpush
