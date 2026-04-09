@extends('layouts.app')
@section('title', 'Payer Commande')
@section('content')
<div class="row">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">💳 Paiement - Commande #{{ $commande->id }}</h5>
            </div>
            <div class="card-body">
                @if ($errors->any())
                    <div class="alert alert-danger">
                        <ul class="mb-0">
                            @foreach ($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif
                
                <form action="{{ route('caisse.traiter', $commande) }}" method="POST" id="paiementForm">
                    @csrf
                    
                    <div class="mb-3">
                        <label class="form-label"><strong>Client (optionnel)</strong></label>
                        <select name="client_id" id="clientId" class="form-select" onchange="onClientChange()">
                            <option value="">— Aucun —</option>
                            @foreach($clients as $c)
                                <option value="{{ $c->id }}" data-points="{{ $c->points_fidelite }}"
                                    {{ old('client_id', $commande->client_id) == $c->id ? 'selected' : '' }}>
                                    {{ $c->nom }} {{ $c->prenom }} ({{ $c->points_fidelite }} pts)
                                </option>
                            @endforeach
                        </select>
                        <small class="text-muted">Pour utiliser les points ou en gagner</small>
                    </div>
                    
                    <div id="pointsFideliteBlock" style="display: none;">
                        <div class="mb-3 p-3 border rounded bg-light">
                            <label class="form-label"><strong>⭐ Points de fidélité</strong></label>
                            <div class="row align-items-end">
                                <div class="col-md-6">
                                    <label class="form-label small">Points à utiliser</label>
                                    <input type="number" name="points_utilises" id="pointsUtilises" class="form-control" 
                                           value="{{ old('points_utilises', 0) }}" min="0" step="1" onchange="updateReste()">
                                </div>
                                <div class="col-md-6">
                                    <p class="mb-0 small text-muted">Équivalent: <strong id="equivalentFcfa">0</strong> FCFA</p>
                                    <p class="mb-0 small text-muted">1 point = {{ number_format($fidelitySettings->valeur_fcfa_1_point, 0, '', ' ') }} FCFA</p>
                                </div>
                            </div>
                            <p class="mb-0 mt-2 small" id="resteLabel">Reste à payer: <strong id="resteFcfa">{{ number_format($commande->montant_total, 0, ',', ' ') }}</strong> FCFA</p>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label"><strong>Moyen de Paiement (pour le reste) *</strong></label>
                        <select name="moyen_paiement" id="moyenPaiement" class="form-select" required onchange="togglePaymentFields()">
                            <option value="">Sélectionner...</option>
                            @foreach($moyensPaiement as $moyen)
                                <option value="{{ $moyen->value }}" {{ old('moyen_paiement') == $moyen->value ? 'selected' : '' }}>
                                    @switch($moyen->value)
                                        @case('especes') 💵 Espèces @break
                                        @case('wave') 📱 Wave @break
                                        @case('orange_money') 📱 Orange Money @break
                                        @case('carte_bancaire') 💳 Carte Bancaire @break
                                        @case('points_fidelite') ⭐ Points de fidélité (total) @break
                                    @endswitch
                                </option>
                            @endforeach
                        </select>
                    </div>
                    
                    <div id="especesFields" style="display: none;">
                        <div class="mb-3">
                            <label class="form-label"><strong>Montant Reçu (FCFA) *</strong></label>
                            <input type="number" name="montant_recu" id="montantRecu" class="form-control" 
                                   value="{{ old('montant_recu', (int) ceil($commande->montant_total)) }}" 
                                   min="0" step="any" oninput="calculateChange()">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label"><strong>Monnaie à Rendre</strong></label>
                            <input type="text" id="monnaieRendue" class="form-control" readonly 
                                   style="font-size: 1.5rem; font-weight: bold; color: #28a745;">
                        </div>
                    </div>
                    
                    <div id="referenceFields" style="display: none;">
                        <div class="mb-3">
                            <label class="form-label"><strong>Référence de transaction (optionnel)</strong></label>
                            <input type="text" name="reference_transaction" class="form-control" 
                                   value="{{ old('reference_transaction') }}" 
                                   placeholder="Ex: réf. Wave / Orange Money si vous l’avez">
                            <small class="text-muted">Si vous laissez vide, une référence est générée automatiquement à l’enregistrement.</small>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Notes</label>
                        <textarea name="notes" class="form-control" rows="2">{{ old('notes') }}</textarea>
                    </div>
                    
                    <hr>
                    
                    <div class="d-flex justify-content-between">
                        <a href="{{ route('caisse.index') }}" class="btn btn-secondary">
                            <i class="bx bx-arrow-back"></i> Retour
                        </a>
                        <button type="submit" class="btn btn-success btn-lg">
                            <i class="bx bx-check"></i> Valider le Paiement
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <div class="col-md-4">
        <div class="card bg-light">
            <div class="card-header">
                <h6 class="mb-0">Résumé de la Commande</h6>
            </div>
            <div class="card-body">
                <div class="mb-3">
                    <strong>Table:</strong> {{ $commande->table->numero }}
                </div>
                
                <div class="mb-3">
                    <strong>Articles:</strong>
                    <ul class="small">
                        @foreach($commande->produits as $produit)
                            <li>{{ $produit->nom }} x{{ $produit->pivot->quantite }} 
                                = {{ number_format($produit->pivot->quantite * $produit->pivot->prix_unitaire, 0, ',', ' ') }} FCFA
                            </li>
                        @endforeach
                    </ul>
                </div>
                
                <hr>
                
                <div class="text-center">
                    <p class="text-muted mb-1">MONTANT TOTAL</p>
                    <h2 class="text-success mb-0">{{ number_format($commande->montant_total, 0, ',', ' ') }} FCFA</h2>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
function togglePaymentFields() {
    const moyenPaiement = document.getElementById('moyenPaiement').value;
    const especesFields = document.getElementById('especesFields');
    const referenceFields = document.getElementById('referenceFields');
    const montantRecuInput = document.getElementById('montantRecu');
    
    if (moyenPaiement === 'especes') {
        especesFields.style.display = 'block';
        referenceFields.style.display = 'none';
        montantRecuInput.required = true;
        montantRecuInput.min = Math.ceil(getResteAPayer());
        calculateChange();
    } else if (moyenPaiement === 'wave' || moyenPaiement === 'orange_money' || moyenPaiement === 'carte_bancaire' || moyenPaiement === 'points_fidelite') {
        especesFields.style.display = 'none';
        referenceFields.style.display = 'block';
        montantRecuInput.required = false;
    } else {
        especesFields.style.display = 'none';
        referenceFields.style.display = 'none';
        montantRecuInput.required = false;
    }
}

function calculateChange() {
    const reste = getResteAPayer();
    const montantRecu = parseFloat(document.getElementById('montantRecu').value) || 0;
    const monnaie = montantRecu - reste;
    
    if (monnaie >= 0) {
        document.getElementById('monnaieRendue').value = new Intl.NumberFormat('fr-FR').format(monnaie) + ' FCFA';
        document.getElementById('monnaieRendue').style.color = '#28a745';
    } else {
        document.getElementById('monnaieRendue').value = 'INSUFFISANT : ' + new Intl.NumberFormat('fr-FR').format(Math.abs(monnaie)) + ' FCFA';
        document.getElementById('monnaieRendue').style.color = '#dc3545';
    }
}

const valeurFcfa1Point = {{ $fidelitySettings->valeur_fcfa_1_point }};
const montantTotal = Math.round({{ $commande->montant_total }});

function getResteAPayer() {
    const pts = parseInt(document.getElementById('pointsUtilises').value) || 0;
    const reduction = pts * valeurFcfa1Point;
    return Math.max(0, montantTotal - reduction);
}

function onClientChange() {
    const sel = document.getElementById('clientId');
    const block = document.getElementById('pointsFideliteBlock');
    const pts = parseInt(sel.options[sel.selectedIndex]?.dataset?.points) || 0;
    block.style.display = pts > 0 ? 'block' : 'none';
    document.getElementById('pointsUtilises').max = pts;
    updateReste();
}

function updateReste() {
    const pts = parseInt(document.getElementById('pointsUtilises').value) || 0;
    const reduction = pts * valeurFcfa1Point;
    const equivalent = Math.min(reduction, montantTotal);
    const reste = montantTotal - equivalent;
    document.getElementById('equivalentFcfa').textContent = new Intl.NumberFormat('fr-FR').format(equivalent);
    document.getElementById('resteFcfa').textContent = new Intl.NumberFormat('fr-FR').format(reste);
    document.getElementById('montantRecu').min = Math.ceil(reste);
    document.getElementById('montantRecu').value = Math.ceil(reste);
    calculateChange();
    const moyenPaiement = document.getElementById('moyenPaiement').value;
    if (reste <= 0 && moyenPaiement !== 'points_fidelite') {
    document.getElementById('moyenPaiement').value = 'points_fidelite';
    togglePaymentFields();
    } else if (reste > 0 && moyenPaiement === 'points_fidelite') {
    document.getElementById('moyenPaiement').value = 'especes';
    togglePaymentFields();
    }
}

document.addEventListener('DOMContentLoaded', function() {
    onClientChange();
    togglePaymentFields();
});
</script>
@endsection

