@extends('layouts.app')
@section('title', 'Nouvel Utilisateur')
@section('content')
<div class="card">
    <div class="card-header"><h5>➕ Nouvel Utilisateur</h5></div>
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
        
        <form action="{{ route('users.store') }}" method="POST">
            @csrf
            
            <div class="mb-3">
                <label class="form-label">Nom Complet *</label>
                <input type="text" name="name" class="form-control @error('name') is-invalid @enderror" value="{{ old('name') }}" required>
                @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            
            <div class="mb-3">
                <label class="form-label">Email *</label>
                <input type="email" name="email" class="form-control @error('email') is-invalid @enderror" value="{{ old('email') }}" required>
                @error('email')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            
            <div class="mb-3">
                <label class="form-label">Mot de Passe *</label>
                <input type="password" name="password" class="form-control @error('password') is-invalid @enderror" required>
                @error('password')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            
            <div class="mb-3">
                <label class="form-label">Confirmer Mot de Passe *</label>
                <input type="password" name="password_confirmation" class="form-control" required>
            </div>

            {{-- PIN pour l'application Serveur --}}
            <div class="mb-3">
                <label class="form-label">🔐 Code PIN <small class="text-muted">(optionnel — 4 chiffres, pour l'application Serveur)</small></label>
                <div class="d-flex align-items-center gap-2" style="max-width:280px">
                    <input type="text" name="pin" id="pin_input"
                           class="form-control @error('pin') is-invalid @enderror"
                           maxlength="4" pattern="[0-9]{4}" placeholder="Ex: 1234"
                           inputmode="numeric" autocomplete="off"
                           value="{{ old('pin') }}">
                    <button type="button" class="btn btn-outline-secondary btn-sm text-nowrap" onclick="generatePin()">
                        <i class="bx bx-refresh"></i> Générer
                    </button>
                </div>
                @error('pin')<div class="text-danger small mt-1">{{ $message }}</div>@enderror
                <div class="text-muted small mt-1">Laissez vide si le serveur créera son PIN lui-même à la première connexion.</div>
            </div>
            
            <div class="mb-3">
                <label class="form-label">Rôles *</label>
                @foreach($roles as $role)
                    <div class="form-check">
                        <input type="checkbox" name="roles[]" value="{{ $role->name }}" class="form-check-input" id="role_{{ $role->id }}" {{ in_array($role->name, old('roles', [])) ? 'checked' : '' }}>
                        <label class="form-check-label" for="role_{{ $role->id }}">
                            <strong>{{ ucfirst($role->name) }}</strong>
                        </label>
                    </div>
                @endforeach
                @error('roles')<div class="text-danger small">{{ $message }}</div>@enderror
            </div>
            
            <div class="d-flex justify-content-between">
                <a href="{{ route('users.index') }}" class="btn btn-secondary">Retour</a>
                <button type="submit" class="btn btn-primary">Créer</button>
            </div>
        </form>
    </div>
</div>

<script>
function generatePin() {
    const pin = Math.floor(1000 + Math.random() * 9000).toString();
    document.getElementById('pin_input').value = pin;
    document.getElementById('pin_input').style.background = '#fff3cd';
    setTimeout(() => document.getElementById('pin_input').style.background = '', 1500);
}
</script>
@endsection
