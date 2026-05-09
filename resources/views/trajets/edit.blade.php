@extends('layouts.app')
@section('title', 'Modifier le trajet')
@section('content')
<div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">✏️ Modifier le trajet</h5>
        <a href="{{ route('trajets.index') }}" class="btn btn-outline-secondary"><i class="bx bx-arrow-back"></i> Retour</a>
    </div>
    <div class="card-body">
        <form method="POST" action="{{ route('trajets.update', $trajet) }}">
            @csrf
            @method('PUT')
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">Départ</label>
                    <input type="text" name="depart" class="form-control @error('depart') is-invalid @enderror" value="{{ old('depart', $trajet->depart) }}" required>
                    @error('depart')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Destination</label>
                    <input type="text" name="destination" class="form-control @error('destination') is-invalid @enderror" value="{{ old('destination', $trajet->destination) }}" required>
                    @error('destination')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
                <div class="col-md-4 mb-3">
                    <label class="form-label">Heure de départ</label>
                    <input type="time" name="heure_depart" class="form-control @error('heure_depart') is-invalid @enderror" value="{{ old('heure_depart', \Illuminate\Support\Str::of($trajet->heure_depart)->limit(5, '')) }}" required>
                    @error('heure_depart')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
                <div class="col-md-4 mb-3 d-flex align-items-end">
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" role="switch" id="actif" name="actif" value="1" {{ old('actif', $trajet->actif ? '1' : '') ? 'checked' : '' }}>
                        <label class="form-check-label" for="actif">Actif</label>
                    </div>
                </div>
            </div>
            <div class="d-flex gap-2">
                <button type="submit" class="btn btn-primary"><i class="bx bx-save"></i> Enregistrer</button>
                <a href="{{ route('trajets.index') }}" class="btn btn-outline-secondary">Annuler</a>
            </div>
        </form>
    </div>
</div>
@endsection
