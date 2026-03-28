@extends('layouts.app')
@section('title', 'Nouvelle Commande')

@push('vendor-css')
    <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
    <style>
        .select2-container--default .select2-selection--single {
            height: 38px;
            border: 1px solid #d9dee3;
            border-radius: 0.375rem;
        }
        .select2-container--default .select2-selection--single .select2-selection__rendered {
            line-height: 38px;
            padding-left: 12px;
            color: #697a8d;
        }
        .select2-container--default .select2-selection--single .select2-selection__arrow {
            height: 36px;
        }
        .select2-container {
            width: 100% !important;
        }
    </style>
@endpush

@push('vendor-js')
    <script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>
@endpush

@section('content')
<div class="card">
    <div class="card-header"><h5>➕ Nouvelle Commande</h5></div>
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
        
        <form action="{{ route('commandes.store') }}" method="POST" id="commandeForm">
            @csrf
            
            <div class="mb-3">
                <label class="form-label">Table *</label>
                <select name="table_id" class="form-select select2-table" required>
                    <option value="">Sélectionner une table</option>
                    @foreach($tables as $table)
                        <option value="{{ $table->id }}" {{ old('table_id') == $table->id ? 'selected' : '' }}>
                            {{ $table->numero }} - Capacité {{ $table->capacite }}
                        </option>
                    @endforeach
                </select>
            </div>
            
            <div class="mb-3">
                <label class="form-label">Notes</label>
                <textarea name="notes" class="form-control" rows="2">{{ old('notes') }}</textarea>
            </div>
            
            <hr>
            
            <h6 class="mb-3">Produits</h6>
            
            <div id="produitsContainer">
                @if(old('produits'))
                    @foreach(old('produits') as $index => $oldProduit)
                    <div class="row mb-2 produit-row">
                        <div class="col-md-5">
                            <select name="produits[{{ $index }}][id]" class="form-select select2-product" required>
                                <option value="">Sélectionner un produit</option>
                                @foreach($produits as $produit)
                                    <option value="{{ $produit->id }}" data-prix="{{ $produit->prix }}" {{ $oldProduit['id'] == $produit->id ? 'selected' : '' }}>
                                        {{ $produit->nom }} - {{ number_format($produit->prix, 0, ',', ' ') }} FCFA
                                    </option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-2">
                            <input type="number" name="produits[{{ $index }}][quantite]" class="form-control" placeholder="Qté" min="1" value="{{ $oldProduit['quantite'] }}" required>
                        </div>
                        <div class="col-md-4">
                            <input type="text" name="produits[{{ $index }}][notes]" class="form-control" placeholder="Notes (optionnel)" value="{{ $oldProduit['notes'] ?? '' }}">
                        </div>
                        <div class="col-md-1">
                            <button type="button" class="btn btn-danger btn-sm remove-produit" onclick="removeProduit(this)"><i class="bx bx-trash"></i></button>
                        </div>
                    </div>
                    @endforeach
                @else
                    <div class="row mb-2 produit-row">
                        <div class="col-md-5">
                            <select name="produits[0][id]" class="form-select select2-product" required>
                                <option value="">Sélectionner un produit</option>
                                @foreach($produits as $produit)
                                    <option value="{{ $produit->id }}" data-prix="{{ $produit->prix }}">
                                        {{ $produit->nom }} - {{ number_format($produit->prix, 0, ',', ' ') }} FCFA
                                    </option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-2">
                            <input type="number" name="produits[0][quantite]" class="form-control" placeholder="Qté" min="1" value="1" required>
                        </div>
                        <div class="col-md-4">
                            <input type="text" name="produits[0][notes]" class="form-control" placeholder="Notes (optionnel)">
                        </div>
                        <div class="col-md-1">
                            <button type="button" class="btn btn-danger btn-sm remove-produit" onclick="removeProduit(this)"><i class="bx bx-trash"></i></button>
                        </div>
                    </div>
                @endif
            </div>
            
            <button type="button" class="btn btn-secondary btn-sm mb-3" onclick="addProduit()">
                <i class="bx bx-plus"></i> Ajouter un produit
            </button>
            
            <hr>
            
            <div class="d-flex justify-content-between">
                <a href="{{ route('commandes.index') }}" class="btn btn-secondary">Retour</a>
                <button type="submit" class="btn btn-primary">Créer la commande</button>
            </div>
        </form>
    </div>
</div>
@endsection

@push('page-js')
<script>
let produitIndex = {{ old('produits') ? count(old('produits')) : 1 }};

const select2SearchDefaults = {
    width: '100%',
    allowClear: true,
    minimumResultsForSearch: 0,
    language: {
        noResults: function () { return 'Aucun résultat'; },
        searching: function () { return 'Recherche…'; }
    }
};

$(document).ready(function () {
    initSelect2();
});

function initSelect2() {
    $('.select2-table').select2(Object.assign({}, select2SearchDefaults, {
        placeholder: 'Sélectionner une table'
    }));
    $('.select2-product').select2(Object.assign({}, select2SearchDefaults, {
        placeholder: 'Sélectionner un produit'
    }));
}

function addProduit() {
    const container = document.getElementById('produitsContainer');
    const newRow = document.createElement('div');
    newRow.className = 'row mb-2 produit-row';
    newRow.innerHTML = `
        <div class="col-md-5">
            <select name="produits[${produitIndex}][id]" class="form-select select2-product" required>
                <option value="">Sélectionner un produit</option>
                @foreach($produits as $produit)
                    <option value="{{ $produit->id }}" data-prix="{{ $produit->prix }}">
                        {{ $produit->nom }} - {{ number_format($produit->prix, 0, ',', ' ') }} FCFA
                    </option>
                @endforeach
            </select>
        </div>
        <div class="col-md-2">
            <input type="number" name="produits[${produitIndex}][quantite]" class="form-control" placeholder="Qté" min="1" value="1" required>
        </div>
        <div class="col-md-4">
            <input type="text" name="produits[${produitIndex}][notes]" class="form-control" placeholder="Notes (optionnel)">
        </div>
        <div class="col-md-1">
            <button type="button" class="btn btn-danger btn-sm remove-produit" onclick="removeProduit(this)"><i class="bx bx-trash"></i></button>
        </div>
    `;
    container.appendChild(newRow);

    $(newRow).find('.select2-product').select2(Object.assign({}, select2SearchDefaults, {
        placeholder: 'Sélectionner un produit'
    }));

    produitIndex++;
}

function removeProduit(button) {
    const container = document.getElementById('produitsContainer');
    if (container.children.length > 1) {
        const $row = $(button).closest('.produit-row');
        $row.find('.select2-product').select2('destroy');
        $row.remove();
    } else {
        alert('Vous devez avoir au moins un produit dans la commande.');
    }
}
</script>
@endpush

