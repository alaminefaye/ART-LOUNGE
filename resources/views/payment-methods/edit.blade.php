@extends('layouts.app')
@section('title', 'Moyens de paiement')
@section('content')
<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">💳 Moyens de paiement (application mobile)</h5>
            </div>
            <div class="card-body">
                <p class="text-muted">Activez ou désactivez Wave et Orange Money pour les <strong>clients</strong> dans l'application mobile. Les changements sont pris en compte dès la prochaine connexion ou actualisation.</p>
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

                <form action="{{ route('payment-methods.update') }}" method="POST">
                    @csrf
                    @method('PUT')

                    <div class="mb-4">
                        <div class="form-check form-switch mb-3">
                            <input class="form-check-input" type="checkbox" name="wave_enabled" id="wave_enabled" value="1"
                                {{ old('wave_enabled', $settings->wave_enabled) ? 'checked' : '' }}>
                            <label class="form-check-label" for="wave_enabled"><strong>Wave</strong> — proposer le paiement Wave aux clients dans l'app mobile</label>
                        </div>
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="orange_money_enabled" id="orange_money_enabled" value="1"
                                {{ old('orange_money_enabled', $settings->orange_money_enabled) ? 'checked' : '' }}>
                            <label class="form-check-label" for="orange_money_enabled"><strong>Orange Money</strong> — proposer le paiement Orange Money aux clients dans l'app mobile</label>
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
