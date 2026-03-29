@extends('layouts.app')
@section('title', 'Commande #' . $commande->id)
@section('content')
@php
    $showSidebar = $commande->statut->value !== 'terminee'
        && $commande->statut->value !== 'annulee'
        && (auth()->user()?->can('update_order_status') || auth()->user()?->can('cancel_orders'));

    $client = $commande->client;
    if (! $client && $commande->user && $commande->user->hasRole('client')) {
        $client = $commande->user->client;
    }
    $clientName = $client?->nom_complet ? trim((string) $client->nom_complet) : '';
    if ($clientName === '' && $commande->user && $commande->user->hasRole('client')) {
        $clientName = trim((string) $commande->user->name);
    }
    $clientPhone = $client?->telephone ? (string) $client->telephone : '';
    if ($clientPhone === '' && $commande->user && $commande->user->hasRole('client') && ! empty($commande->user->phone)) {
        $clientPhone = (string) $commande->user->phone;
    }
@endphp
<div class="row">
    <div class="{{ $showSidebar ? 'col-12 col-lg-8' : 'col-12' }}">
        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between">
                <h5 class="mb-0">📋 Commande #{{ $commande->id }}</h5>
                <div>
                    @if($commande->statut->value !== 'annulee')
                        <a href="{{ route('commandes.print-receipt', $commande) }}" class="btn btn-sm btn-info" target="_blank">
                            <i class="bx bx-printer"></i> Imprimer
                        </a>
                    @endif
                    @if($commande->statut->value !== 'terminee' && $commande->statut->value !== 'annulee')
                        @can('update_orders')
                        <a href="{{ route('commandes.edit', $commande) }}" class="btn btn-sm btn-warning">
                            <i class="bx bx-edit"></i> Modifier
                        </a>
                        @endcan
                    @endif
                    <a href="{{ route('commandes.index') }}" class="btn btn-sm btn-label-secondary">
                        <i class="bx bx-arrow-back"></i> Retour
                    </a>
                </div>
            </div>
            <div class="card-body">
                <div class="row mb-3">
                    <div class="col-12 col-md-6">
                        <strong>Table :</strong>
                        <p class="text-primary h4">{{ $commande->table->numero }}</p>
                    </div>
                    <div class="col-12 col-md-6">
                        <strong>Serveur :</strong>
                        <p>{{ $commande->user->name ?? 'N/A' }}</p>
                    </div>
                </div>

                @if($clientName !== '' || $clientPhone !== '')
                    <div class="row mb-3">
                        <div class="col-12 col-md-6">
                            <strong>Client :</strong>
                            <p class="mb-0">{{ $clientName !== '' ? $clientName : '—' }}</p>
                        </div>
                        <div class="col-12 col-md-6">
                            <strong>Téléphone :</strong>
                            <p class="mb-0">{{ $clientPhone !== '' ? $clientPhone : '—' }}</p>
                        </div>
                    </div>
                @endif
                
                <div class="row mb-3">
                    <div class="col-md-6">
                        <strong>Statut :</strong>
                        <p>
                            @switch($commande->statut->value)
                                @case('attente')
                                    <span class="badge bg-warning">En attente</span>
                                    @break
                                @case('preparation')
                                    <span class="badge bg-info">En préparation</span>
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
                        </p>
                    </div>
                    <div class="col-md-6">
                        <strong>Date :</strong>
                        <p>{{ $commande->created_at->format('d/m/Y à H:i') }}</p>
                    </div>
                </div>
                
                @if($commande->notes)
                    <div class="mb-3">
                        <strong>Notes :</strong>
                        <p class="text-muted">{{ $commande->notes }}</p>
                    </div>
                @endif
                
                <hr>
                
                <h6 class="mb-3">Articles commandés</h6>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Produit</th>
                            <th>Quantité</th>
                            <th>Prix unitaire</th>
                            <th>Sous-total</th>
                            <th>Notes</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($commande->produits as $produit)
                        <tr>
                            <td><strong>{{ $produit->nom }}</strong><br><small class="text-muted">{{ $produit->categorie->nom ?? '' }}</small></td>
                            <td>x{{ $produit->pivot->quantite }}</td>
                            <td>{{ number_format($produit->pivot->prix_unitaire, 0, ',', ' ') }} FCFA</td>
                            <td><strong>{{ number_format($produit->pivot->quantite * $produit->pivot->prix_unitaire, 0, ',', ' ') }} FCFA</strong></td>
                            <td><small class="text-muted">{{ $produit->pivot->notes ?? '-' }}</small></td>
                        </tr>
                        @endforeach
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="3" class="text-end"><strong>TOTAL :</strong></td>
                            <td colspan="2"><strong class="h4 text-success">{{ number_format($commande->montant_total, 0, ',', ' ') }} FCFA</strong></td>
                        </tr>
                    </tfoot>
                </table>
            </div>
        </div>
    </div>
    
    @if($showSidebar)
        <div class="col-12 col-lg-4">
            @can('update_order_status')
                <div class="card">
                    <div class="card-header"><h6 class="mb-0">Changer le statut</h6></div>
                    <div class="card-body">
                        <form action="{{ route('commandes.update-status', $commande) }}" method="POST">
                            @csrf
                            @method('PATCH')
                            <div class="mb-3">
                                <select name="statut" class="form-select" required>
                                    <option value="attente" {{ $commande->statut->value === 'attente' ? 'selected' : '' }}>En attente</option>
                                    <option value="preparation" {{ $commande->statut->value === 'preparation' ? 'selected' : '' }}>En préparation</option>
                                    <option value="servie" {{ $commande->statut->value === 'servie' ? 'selected' : '' }}>Servie</option>
                                    <option value="terminee" {{ $commande->statut->value === 'terminee' ? 'selected' : '' }}>Terminée</option>
                                </select>
                            </div>
                            <button type="submit" class="btn btn-primary w-100">Mettre à jour</button>
                        </form>
                    </div>
                </div>
            @endcan

            @can('cancel_orders')
                <div class="card mt-3">
                    <div class="card-header"><h6 class="mb-0 text-danger">Actions</h6></div>
                    <div class="card-body">
                        <form action="{{ route('commandes.destroy', $commande) }}" method="POST" onsubmit="return confirm('Annuler cette commande ?')">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="btn btn-danger w-100">
                                <i class="bx bx-x"></i> Annuler la commande
                            </button>
                        </form>
                    </div>
                </div>
            @endcan
        </div>
    @endif
</div>
@endsection
