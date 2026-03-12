@extends('layouts.app')
@section('title', 'Paramètres fidélité')
@section('content')
<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">⭐ Paramètres des points de fidélité</h5>
            </div>
            <div class="card-body">
                @if (session('success'))
                    <div class="alert alert-success">{{ session('success') }}</div>
                @endif
                @if ($errors->any())
                    <div class="alert alert-danger">
                        <ul class="mb-0">
                            @foreach ($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                <form action="{{ route('fidelity.update') }}" method="POST">
                    @csrf
                    @method('PUT')

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label"><strong>Attribution des points</strong></label>
                                <p class="text-muted small">Pour chaque <input type="number" name="fcfa_pour_1_point" 
                                    value="{{ old('fcfa_pour_1_point', $settings->fcfa_pour_1_point) }}" 
                                    min="1" class="form-control form-control-sm d-inline-block" style="width: 120px;"> FCFA dépensés, le client gagne <strong>1 point</strong>.</p>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label"><strong>Utilisation des points</strong></label>
                                <p class="text-muted small">1 point = <input type="number" name="valeur_fcfa_1_point" 
                                    value="{{ old('valeur_fcfa_1_point', $settings->valeur_fcfa_1_point) }}" 
                                    min="0.01" step="0.01" class="form-control form-control-sm d-inline-block" style="width: 120px;"> FCFA de réduction sur la facture.</p>
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="actif" id="actif" value="1" 
                                {{ old('actif', $settings->actif) ? 'checked' : '' }}>
                            <label class="form-check-label" for="actif">Programme fidélité actif</label>
                        </div>
                    </div>

                    <hr>
                    <button type="submit" class="btn btn-primary">
                        <i class="bx bx-save"></i> Enregistrer
                    </button>
                    <a href="{{ route('dashboard') }}" class="btn btn-secondary">Annuler</a>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection
