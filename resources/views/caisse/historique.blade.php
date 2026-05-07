@extends('layouts.app')
@section('title', 'Historique des Paiements')
@section('content')
<div class="card">
    <div class="card-header d-flex justify-content-between">
        <h5 class="mb-0">📋 Historique des Paiements</h5>
        <a href="{{ route('caisse.index') }}" class="btn btn-primary">
            <i class="bx bx-arrow-back"></i> Retour à la Caisse
        </a>
    </div>
    <div class="card-body">
        <!-- 🔍 SECTION RECHERCHE & FILTRES -->
        <div class="row mb-4">
            <div class="col-md-3 mb-3">
                <div class="input-group">
                    <span class="input-group-text"><i class="bx bx-search"></i></span>
                    <input type="text" id="searchInput" class="form-control" placeholder="Rechercher #Facture...">
                </div>
            </div>
            
            <div class="col-md-3 mb-3">
                <select id="filterMoyen" class="form-select">
                    <option value="">💳 Tous moyens</option>
                    <option value="especes">💵 Espèces</option>
                    <option value="wave">📱 Wave</option>
                    <option value="orange_money">📱 Orange Money</option>
                    <option value="carte_bancaire">💳 Carte</option>
                </select>
            </div>
            
            <div class="col-md-3 mb-3">
                <select id="filterStatut" class="form-select">
                    <option value="">📊 Tous statuts</option>
                    <option value="validé">✅ Validé</option>
                    <option value="attente">⏳ En attente</option>
                    <option value="échoué">❌ Échoué</option>
                    <option value="remboursé">🔄 Remboursé</option>
                </select>
            </div>
            
            <div class="col-md-3 mb-3">
                <button id="resetFilters" class="btn btn-outline-secondary w-100">
                    <i class="bx bx-reset"></i> Réinitialiser
                </button>
            </div>
        </div>
        
        <!-- Résultats de recherche -->
        <div id="searchResults" class="alert alert-info d-none mb-3">
            <i class="bx bx-info-circle"></i> <span id="resultCount">0</span> paiement(s) trouvé(s)
        </div>
        
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Facture</th>
                        <th>Commande</th>
                        <th>Table</th>
                        <th>Personnel</th>
                        <th>Moyen</th>
                        <th>Montant</th>
                        <th>Statut</th>
                        <th>Date</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="paiementsTableBody">
                    @forelse($paiements as $paiement)
                    <tr>
                        <td><strong>{{ $paiement->facture->numero_facture ?? 'N/A' }}</strong></td>
                        <td>#{{ $paiement->commande->id }}</td>
                        <td><span class="badge bg-primary">{{ $paiement->commande->table?->numero ?? 'À emporter' }}</span></td>
                        <td>{{ $paiement->user->name ?? 'N/A' }}</td>
                        <td>
                            @switch($paiement->moyen_paiement->value)
                                @case('especes') 💵 Espèces @break
                                @case('wave') 📱 Wave @break
                                @case('orange_money') 📱 Orange Money @break
                                @case('carte_bancaire') 💳 Carte @break
                            @endswitch
                        </td>
                        <td><strong>{{ number_format($paiement->montant, 0, ',', ' ') }} FCFA</strong></td>
                        <td>
                            @switch($paiement->statut->value)
                                @case('valide')
                                    <span class="badge bg-success">Validé</span>
                                    @break
                                @case('en_attente')
                                    <span class="badge bg-warning">En attente</span>
                                    @break
                                @case('echoue')
                                    <span class="badge bg-danger">Échoué</span>
                                    @break
                                @case('rembourse')
                                    <span class="badge bg-secondary">Remboursé</span>
                                    @break
                            @endswitch
                        </td>
                        <td>{{ $paiement->created_at->format('d/m/Y H:i') }}</td>
                        <td>
                            @if($paiement->facture)
                                <a href="{{ route('caisse.facture', $paiement->facture) }}" class="btn btn-sm btn-info" title="Voir la facture">
                                    <i class="bx bx-file"></i>
                                </a>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr class="no-results">
                        <td colspan="9" class="text-center text-muted">Aucun paiement trouvé</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        
        <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-3 mt-3 pt-3 border-top">
            <div class="text-muted small">
                @if($paiements->total() > 0)
                    Affichage de <strong>{{ $paiements->firstItem() }}</strong> à <strong>{{ $paiements->lastItem() }}</strong>
                    sur <strong>{{ $paiements->total() }}</strong> paiement(s)
                @endif
            </div>
            {{ $paiements->links() }}
        </div>
    </div>
</div>
@endsection

@push('page-js')
<script>
document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('searchInput');
    const filterMoyen = document.getElementById('filterMoyen');
    const filterStatut = document.getElementById('filterStatut');
    const resetBtn = document.getElementById('resetFilters');
    const tableBody = document.getElementById('paiementsTableBody');
    const searchResults = document.getElementById('searchResults');
    const resultCount = document.getElementById('resultCount');
    const allRows = tableBody.querySelectorAll('tr:not(.no-results)');
    
    function filterPaiements() {
        const searchTerm = searchInput.value.toLowerCase();
        const moyenFilter = filterMoyen.value.toLowerCase();
        const statutFilter = filterStatut.value.toLowerCase();
        let visibleCount = 0;
        
        allRows.forEach(row => {
            const facture = row.querySelector('td:nth-child(1)').textContent.toLowerCase();
            const moyen = row.querySelector('td:nth-child(5)').textContent.toLowerCase();
            const statut = row.querySelector('td:nth-child(7)').textContent.toLowerCase();
            
            const matchSearch = facture.includes(searchTerm);
            const matchMoyen = !moyenFilter || moyen.includes(moyenFilter);
            const matchStatut = !statutFilter || statut.includes(statutFilter);
            
            if (matchSearch && matchMoyen && matchStatut) {
                row.style.display = '';
                visibleCount++;
            } else {
                row.style.display = 'none';
            }
        });
        
        if (searchTerm || moyenFilter || statutFilter) {
            searchResults.classList.remove('d-none');
            resultCount.textContent = visibleCount;
        } else {
            searchResults.classList.add('d-none');
        }
    }
    
    searchInput.addEventListener('keyup', filterPaiements);
    filterMoyen.addEventListener('change', filterPaiements);
    filterStatut.addEventListener('change', filterPaiements);
    
    resetBtn.addEventListener('click', function() {
        searchInput.value = '';
        filterMoyen.value = '';
        filterStatut.value = '';
        searchResults.classList.add('d-none');
        allRows.forEach(row => row.style.display = '');
    });
});
</script>
@endpush
