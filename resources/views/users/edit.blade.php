@extends('layouts.app')
@section('title', 'Modifier Utilisateur')
@section('content')
<div class="card">
    <div class="card-header"><h5>✏️ Modifier {{ $user->name }}</h5></div>
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
        
        <form action="{{ route('users.update', $user) }}" method="POST">
            @csrf @method('PUT')
            
            <div class="mb-3">
                <label class="form-label">Nom Complet *</label>
                <input type="text" name="name" class="form-control" value="{{ old('name', $user->name) }}" required>
            </div>
            
            <div class="mb-3">
                <label class="form-label">Email *</label>
                <input type="email" name="email" class="form-control" value="{{ old('email', $user->email) }}" required>
            </div>
            
            <div class="mb-3">
                <label class="form-label">Nouveau Mot de Passe <small class="text-muted">(laisser vide pour ne pas changer)</small></label>
                <input type="password" name="password" class="form-control">
            </div>
            
            <div class="mb-3">
                <label class="form-label">Confirmer Nouveau Mot de Passe</label>
                <input type="password" name="password_confirmation" class="form-control">
            </div>

            {{-- PIN pour l'application Serveur --}}
            <div class="mb-3">
                <label class="form-label">🔐 Code PIN — Application Serveur</label>
                <div class="mb-2">
                    @if($user->hasPin())
                        <span class="badge bg-success fs-6">✅ PIN défini</span>
                        <span class="text-muted small ms-2">Le serveur a un PIN configuré.</span>
                    @else
                        <span class="badge bg-secondary fs-6">❌ Aucun PIN</span>
                        <span class="text-muted small ms-2">Le serveur n'a pas encore de PIN.</span>
                    @endif
                </div>
                <div class="d-flex align-items-center gap-2" style="max-width:280px">
                    <input type="text" name="pin" id="pin_input_edit"
                           class="form-control @error('pin') is-invalid @enderror"
                           maxlength="4" pattern="[0-9]{4}"
                           placeholder="{{ $user->hasPin() ? 'Nouveau PIN (remplace l\'ancien)' : 'Ex: 1234' }}"
                           inputmode="numeric" autocomplete="off">
                    <button type="button" class="btn btn-outline-secondary btn-sm text-nowrap" onclick="generatePinEdit()">
                        <i class="bx bx-refresh"></i> Générer
                    </button>
                </div>
                @error('pin')<div class="text-danger small mt-1">{{ $message }}</div>@enderror
                <div class="text-muted small mt-1">Laissez vide pour conserver le PIN actuel.</div>
            </div>
            
            <div class="mb-3">
                <label class="form-label">Rôles *</label>
                @foreach($roles as $role)
                    <div class="form-check">
                        <input type="checkbox" name="roles[]" value="{{ $role->name }}" class="form-check-input" id="role_{{ $role->id }}" 
                               {{ $user->hasRole($role->name) ? 'checked' : '' }}>
                        <label class="form-check-label" for="role_{{ $role->id }}">
                            <strong>{{ ucfirst($role->name) }}</strong>
                        </label>
                    </div>
                @endforeach
            </div>
            
            <div class="d-flex justify-content-between">
                <a href="{{ route('users.index') }}" class="btn btn-secondary">Retour</a>
                <button type="submit" class="btn btn-primary">Enregistrer</button>
            </div>
        </form>
    </div>
</div>

<script>
function generatePinEdit() {
    const pin = Math.floor(1000 + Math.random() * 9000).toString();
    const input = document.getElementById('pin_input_edit');
    input.value = pin;
    input.style.background = '#fff3cd';
    setTimeout(() => input.style.background = '', 1500);
}
</script>
@endsection
