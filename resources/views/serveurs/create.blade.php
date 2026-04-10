@extends('layouts.app')

@section('title', 'Ajouter un Serveur')

@section('content')
<div class="row">
    <div class="col-xl">
        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">Nouveau Serveur</h5>
                <a href="{{ route('serveurs.index') }}" class="btn btn-secondary btn-sm">Retour</a>
            </div>
            <div class="card-body">
                <form action="{{ route('serveurs.store') }}" method="POST">
                    @csrf
                    
                    <div class="mb-3">
                        <label class="form-label" for="nom">Nom *</label>
                        <input type="text" class="form-control" id="nom" name="nom" value="{{ old('nom') }}" required />
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label" for="prenom">Prénom</label>
                        <input type="text" class="form-control" id="prenom" name="prenom" value="{{ old('prenom') }}" />
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="telephone">Téléphone</label>
                        <input type="text" class="form-control" id="telephone" name="telephone" value="{{ old('telephone') }}" />
                    </div>

                    <div class="mb-3 form-check">
                        <input type="checkbox" class="form-check-input" id="actif" name="actif" value="1" {{ old('actif', true) ? 'checked' : '' }} />
                        <label class="form-check-label" for="actif">Serveur actif</label>
                    </div>

                    <button type="submit" class="btn btn-primary">Enregistrer</button>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection
