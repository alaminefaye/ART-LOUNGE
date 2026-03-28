@extends('layouts.app')
@section('title', 'Détails Réservation #' . $reservation->id)
@section('content')
<div class="row">
    <div class="col-xl-9 col-md-8 col-12 mb-md-0 mb-4">
        <div class="card invoice-preview-card">
            <div class="card-body">
                <div class="d-flex justify-content-between flex-xl-row flex-md-column flex-sm-row flex-column p-sm-3 p-0">
                    <div class="mb-xl-0 mb-4">
                        <div class="d-flex svg-illustration mb-3 gap-2">
                            <span class="app-brand-logo demo">
                                <i class="bx bx-calendar fs-3"></i>
                            </span>
                            <span class="app-brand-text demo text-body fw-bolder">Réservation #{{ $reservation->id }}</span>
                        </div>
                        <p class="mb-1">Date de création: {{ $reservation->created_at->format('d/m/Y H:i') }}</p>
                        <p class="mb-0">Créé par: {{ $reservation->user ? $reservation->user->name : 'Client (App Mobile)' }}</p>
                    </div>
                    <div>
                        <h4>Statut: 
                            @switch($reservation->statut->value)
                                @case('attente')
                                    <span class="badge bg-warning">En attente</span>
                                    @break
                                @case('confirmee')
                                    <span class="badge bg-success">Confirmée</span>
                                    @break
                                @case('en_cours')
                                    <span class="badge bg-primary">En cours</span>
                                    @break
                                @case('terminee')
                                    <span class="badge bg-secondary">Terminée</span>
                                    @break
                                @case('annulee')
                                    <span class="badge bg-danger">Annulée</span>
                                    @break
                            @endswitch
                        </h4>
                        <div class="mb-1">
                            <span class="me-1">Date prévue:</span>
                            <span class="fw-bold">{{ $reservation->date_reservation->format('d/m/Y') }}</span>
                        </div>
                        <div>
                            <span class="me-1">Heure:</span>
                            <span class="fw-bold">{{ $reservation->heure_debut->format('H:i') }} - {{ $reservation->heure_fin ? $reservation->heure_fin->format('H:i') : '' }}</span>
                        </div>
                    </div>
                </div>
            </div>
            <hr class="my-0" />
            <div class="card-body">
                <div class="row p-sm-3 p-0">
                    <div class="col-xl-6 col-md-12 col-sm-5 col-12 mb-xl-0 mb-md-4 mb-sm-0 mb-4">
                        <h6 class="pb-2">Client:</h6>
                        <p class="mb-1"><span class="fw-bold">{{ $reservation->nom_client }}</span></p>
                        <p class="mb-1"><i class="bx bx-phone me-1"></i> {{ $reservation->telephone }}</p>
                        @if($reservation->email)
                            <p class="mb-1"><i class="bx bx-envelope me-1"></i> {{ $reservation->email }}</p>
                        @endif
                    </div>
                    <div class="col-xl-6 col-md-12 col-sm-7 col-12">
                        <h6 class="pb-2">Détails:</h6>
                        <table>
                            <tbody>
                                <tr>
                                    <td class="pe-3">Table:</td>
                                    <td>
                                        @if($reservation->table)
                                            <span class="fw-bold">Table {{ $reservation->table->numero }}</span> 
                                            <small class="text-muted">({{ $reservation->table->type->displayName }})</small>
                                        @else
                                            <span class="text-danger">Table supprimée</span>
                                        @endif
                                    </td>
                                </tr>
                                <tr>
                                    <td class="pe-3">Personnes:</td>
                                    <td>{{ $reservation->nombre_personnes }}</td>
                                </tr>
                                <tr>
                                    <td class="pe-3">Durée:</td>
                                    <td>{{ $reservation->duree }}h</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            
            @if($reservation->notes)
            <hr class="my-0" />
            <div class="card-body">
                <div class="row p-sm-3 p-0">
                    <div class="col-12">
                        <h6 class="pb-2">Notes:</h6>
                        <p>{{ $reservation->notes }}</p>
                    </div>
                </div>
            </div>
            @endif

            <hr class="my-0" />
            <div class="card-body">
                <div class="row p-sm-3 p-0">
                    <div class="col-md-6 mb-md-0 mb-3">
                    </div>
                    <div class="col-md-6 d-flex justify-content-end">
                        <div class="invoice-calculations">
                            <div class="d-flex justify-content-between mb-2">
                                <span class="w-px-100">Prix Total:</span>
                                <span class="fw-bold">{{ number_format($reservation->prix_total, 0, ',', ' ') }} FCFA</span>
                            </div>
                            @if($reservation->acompte > 0)
                            <div class="d-flex justify-content-between mb-2">
                                <span class="w-px-100">Acompte:</span>
                                <span class="fw-bold text-success">- {{ number_format($reservation->acompte, 0, ',', ' ') }} FCFA</span>
                            </div>
                            <hr />
                            <div class="d-flex justify-content-between">
                                <span class="w-px-100">Reste:</span>
                                <span class="fw-bold">{{ number_format($reservation->prix_total - $reservation->acompte, 0, ',', ' ') }} FCFA</span>
                            </div>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-xl-3 col-md-4 col-12 invoice-actions">
        <div class="card">
            <div class="card-body">
                @can('manage_reservations')
                <a href="{{ route('reservations.edit', $reservation) }}" class="btn btn-primary d-grid w-100 mb-3">
                    <span class="d-flex align-items-center justify-content-center text-nowrap"><i class="bx bx-edit me-1"></i> Modifier</span>
                </a>
                
                @if($reservation->statut->value === 'attente')
                    <form action="{{ route('reservations.confirm', $reservation) }}" method="POST">
                        @csrf
                        <button type="submit" class="btn btn-success d-grid w-100 mb-3">
                            <span class="d-flex align-items-center justify-content-center text-nowrap"><i class="bx bx-check me-1"></i> Confirmer</span>
                        </button>
                    </form>
                @endif

                @if($reservation->statut->value !== 'annulee' && $reservation->statut->value !== 'terminee')
                    <form action="{{ route('reservations.cancel', $reservation) }}" method="POST" onsubmit="return confirm('Êtes-vous sûr de vouloir annuler cette réservation ?');">
                        @csrf
                        <button type="submit" class="btn btn-danger d-grid w-100 mb-3">
                            <span class="d-flex align-items-center justify-content-center text-nowrap"><i class="bx bx-x me-1"></i> Annuler</span>
                        </button>
                    </form>
                @endif
                @endcan

                <a href="{{ route('reservations.index') }}" class="btn btn-label-secondary d-grid w-100">
                    Retour à la liste
                </a>
            </div>
        </div>
    </div>
</div>
@endsection
