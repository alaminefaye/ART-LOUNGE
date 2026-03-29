@extends('layouts.app')

@push('page-css')
<style>
    @media print {
        @page { size: A4; margin: 8mm; }
        html, body { font-size: 11px !important; line-height: 1.2 !important; }
        .layout-menu, .layout-navbar, .footer, .no-print, .content-backdrop, .navbar-nav-right {
            display: none !important;
        }
        .layout-wrapper, .layout-container, .layout-page, .content-wrapper {
            padding: 0 !important;
            margin: 0 !important;
        }
        .container, .container-fluid { max-width: none !important; width: 100% !important; padding: 0 !important; }
        body { background: #fff !important; padding: 0 !important; }
        .card { border: 1px solid #e5e7eb !important; box-shadow: none !important; }
        .print-area { margin: 0 !important; max-width: none !important; }

        .report-header { padding: 10px 12px !important; margin-bottom: 10px !important; }
        .report-brand img { height: 40px !important; }
        .report-title h1 { font-size: 14px !important; }
        .report-title .meta { font-size: 10px !important; margin-top: 2px !important; }
        .report-badge { font-size: 10px !important; padding: 4px 8px !important; }
        .pill { font-size: 10px !important; padding: 4px 8px !important; }
        .kv { gap: 8px !important; }
        .kv .item { padding: 8px 10px !important; }
        .kv .k { font-size: 10px !important; }
        .kv .v { font-size: 12px !important; margin-top: 2px !important; }
        .card-header { padding-top: 10px !important; padding-bottom: 10px !important; }
        .card-body { padding: 12px !important; }
        .table-report th { font-size: 10px !important; padding-top: 8px !important; padding-bottom: 8px !important; }
        .table-report td { padding-top: 8px !important; padding-bottom: 8px !important; }
        .row.g-3 { --bs-gutter-x: .75rem !important; --bs-gutter-y: .75rem !important; }
    }
    .print-area { max-width: 980px; margin: 0 auto; }
    .report-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 16px;
        padding: 18px 20px;
        border: 1px solid rgba(67, 89, 113, 0.15);
        border-radius: 12px;
        background: #fff;
        margin-bottom: 18px;
    }
    .report-brand { display: flex; align-items: center; gap: 12px; min-width: 0; }
    .report-brand img { height: 52px; width: auto; display: block; }
    .report-title { min-width: 0; }
    .report-title h1 { font-size: 18px; margin: 0; line-height: 1.2; }
    .report-title .meta { font-size: 12px; color: #6b7280; margin-top: 4px; }
    .report-badge {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 6px 10px;
        border-radius: 999px;
        background: rgba(105, 108, 255, 0.12);
        color: #2e2f8f;
        font-weight: 600;
        font-size: 12px;
        white-space: nowrap;
    }
    .report-card { border: 1px solid rgba(67, 89, 113, 0.15); border-radius: 12px; overflow: hidden; }
    .report-card .card-header { background: #fff; border-bottom: 1px solid rgba(67, 89, 113, 0.12); }
    .kv { display: grid; grid-template-columns: 1fr; gap: 10px; }
    .kv .item { padding: 10px 12px; border: 1px solid rgba(67, 89, 113, 0.12); border-radius: 10px; background: #fff; }
    .kv .k { font-size: 11px; color: #6b7280; text-transform: uppercase; letter-spacing: 0.04em; }
    .kv .v { font-size: 14px; font-weight: 600; margin-top: 4px; color: #111827; }
    .money { font-variant-numeric: tabular-nums; }
    .table-report { width: 100%; margin: 0; }
    .table-report th { font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; color: #6b7280; border-bottom: 1px solid rgba(67, 89, 113, 0.12) !important; }
    .table-report td { border-bottom: 1px solid rgba(67, 89, 113, 0.08); vertical-align: middle; }
    .table-report tr:last-child td { border-bottom: 0; }
    .pill {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 6px 10px;
        border-radius: 999px;
        background: rgba(67, 89, 113, 0.06);
        font-weight: 600;
        font-size: 12px;
        color: #111827;
    }
    .sum-row { background: rgba(105, 108, 255, 0.07); }
    .accent-left { border-left: 4px solid #696cff !important; }
</style>
@endpush

@section('content')
<div class="container-fluid py-4">
    <div class="no-print d-flex align-items-center justify-content-between mb-4 flex-wrap gap-2">
        <a href="{{ route('caisse.sessions.index') }}" class="btn btn-outline-secondary btn-sm">
            <i class="bx bx-arrow-back me-1"></i> Retour à l'historique
        </a>
        <button type="button" class="btn btn-primary" onclick="window.print()">
            <i class="bx bx-printer me-1"></i> Imprimer le rapport
        </button>
    </div>

    <div class="print-area">
        <div class="report-header">
            <div class="report-brand">
                <img src="{{ asset('assets/img/logo.png') }}" alt="Logo">
                <div class="report-title">
                    <h1>Rapport de session de caisse</h1>
                    <div class="meta">{{ config('app.name') }} — Imprimé le {{ now()->format('d/m/Y à H:i') }}</div>
                </div>
            </div>
            <div class="report-badge">
                <i class="bx bx-check-shield"></i>
                Session clôturée
            </div>
        </div>

        <div class="row g-3 mb-3">
            <div class="col-12 col-lg-5">
                <div class="card report-card shadow-sm">
                    <div class="card-header py-3">
                        <div class="d-flex align-items-center justify-content-between">
                            <div class="fw-semibold text-primary">Informations session</div>
                            <span class="pill"><i class="bx bx-user"></i> {{ $session->user->name }}</span>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="kv">
                            <div class="item">
                                <div class="k">Ouverture</div>
                                <div class="v">{{ $session->opened_at->format('d/m/Y à H:i') }}</div>
                            </div>
                            <div class="item">
                                <div class="k">Clôture</div>
                                <div class="v">{{ $session->closed_at?->format('d/m/Y à H:i') ?? '—' }}</div>
                            </div>
                            <div class="item">
                                <div class="k">Fond de caisse</div>
                                <div class="v money">{{ number_format($session->solde_ouverture, 0, ',', ' ') }} FCFA</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

                </div>
            </div>
        </div>

        @if($details['points_details']->isNotEmpty())
        <div class="card report-card shadow-sm mb-3">
            <div class="card-header py-3">
                <div class="fw-semibold text-primary">Détails de l'utilisation des Points</div>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-report align-middle mb-0">
                        <thead class="bg-light">
                            <tr>
                                <th class="px-4 py-3">Client</th>
                                <th class="py-3 text-center">Cmd #</th>
                                <th class="py-3 text-center">Points</th>
                                <th class="px-4 py-3 text-end">Réduction</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($details['points_details'] as $p)
                            <tr>
                                <td class="px-4 py-3">
                                    <span class="fw-semibold">{{ $p->client->nomComplet ?? 'Client inconnu' }}</span>
                                </td>
                                <td class="py-3 text-center">
                                    <a href="{{ route('commandes.show', $p->commande_id) }}" class="fw-bold">
                                        #{{ $p->commande_id }}
                                    </a>
                                    <div class="small text-muted" style="font-size: 10px;">{{ $p->commande->table->nom ?? 'Table' }}</div>
                                </td>
                                <td class="py-3 text-center">
                                    <span class="badge bg-label-info">{{ $p->points_utilises }} pts</span>
                                </td>
                                <td class="px-4 py-3 text-end fw-bold money">{{ number_format($p->montant, 0, ',', ' ') }} FCFA</td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        @endif

        <div class="card report-card shadow-sm accent-left">
            <div class="card-header py-3">
                <div class="fw-semibold text-primary">Synthèse caisse</div>
            </div>
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-12 col-md-4">
                        <div class="kv">
                            <div class="item">
                                <div class="k">Total attendu en caisse</div>
                                <div class="v money">{{ number_format($session->total_attendu, 0, ',', ' ') }} FCFA</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-md-4">
                        <div class="kv">
                            <div class="item">
                                <div class="k">Montant réel compté</div>
                                <div class="v money text-primary">{{ number_format($session->solde_fermeture_reel, 0, ',', ' ') }} FCFA</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-md-4">
                        <div class="kv">
                            <div class="item">
                                <div class="k">Écart</div>
                                <div class="v money">
                                    @if(abs($ecart) < 0.01)
                                        <span class="text-success"><i class="bx bx-check-circle me-1"></i> Correct (0)</span>
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
        </div>
    </div>
</div>
@endsection
