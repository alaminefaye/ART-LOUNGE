@extends('layouts.app')
@section('title', 'Détails Utilisateur')
@section('content')
<div class="card">
    <div class="card-header d-flex justify-content-between">
        <h5 class="mb-0">👤 {{ $user->name }}</h5>
        <div>
            @can('manage_users')
                <a href="{{ route('users.edit', $user) }}" class="btn btn-sm btn-warning">
                    <i class="bx bx-edit"></i> Modifier
                </a>
            @endcan
            <a href="{{ route('users.index') }}" class="btn btn-sm btn-label-secondary">
                <i class="bx bx-arrow-back"></i> Retour
            </a>
        </div>
    </div>
    <div class="card-body">
        <div class="row mb-3">
            <div class="col-md-6">
                <strong>Nom :</strong>
                <p>{{ $user->name }}</p>
            </div>
            <div class="col-md-6">
                <strong>Email :</strong>
                <p>{{ $user->email }}</p>
            </div>
        </div>
        
        <div class="row mb-3">
            <div class="col-md-6">
                <strong>Créé le :</strong>
                <p>{{ $user->created_at->format('d/m/Y à H:i') }}</p>
            </div>
            <div class="col-md-6">
                <strong>Dernière modification :</strong>
                <p>{{ $user->updated_at->format('d/m/Y à H:i') }}</p>
            </div>
        </div>

        <div class="row mb-3">
            <div class="col-md-6">
                <strong>🔐 Code PIN (App Serveur) :</strong>
                <p class="mt-1">
                    @if($user->hasPin())
                        <span class="badge bg-success">✅ PIN configuré</span>
                    @else
                        <span class="badge bg-secondary">❌ Aucun PIN</span>
                        <span class="text-muted small d-block mt-1">Le serveur peut créer son PIN à la 1ère connexion sur l'app, ou l'admin peut l'assigner via Modifier.</span>
                    @endif
                </p>
            </div>
        </div>
        
        <hr>
        
        <h6 class="mb-3">Rôles</h6>
        <div class="mb-4">
            @forelse($user->roles as $role)
                <span class="badge bg-{{ $role->name === 'admin' ? 'danger' : ($role->name === 'manager' ? 'warning' : 'secondary') }} me-2">
                    {{ ucfirst($role->name) }}
                </span>
            @empty
                <p class="text-muted">Aucun rôle attribué</p>
            @endforelse
        </div>
        
        <h6 class="mb-3">Permissions (via rôles)</h6>
        <div class="row">
            @foreach($user->roles as $role)
                <div class="col-md-6 mb-3">
                    <strong>{{ ucfirst($role->name) }} :</strong>
                    <ul class="small">
                        @foreach($role->permissions->take(10) as $permission)
                            <li>{{ $permission->name }}</li>
                        @endforeach
                        @if($role->permissions->count() > 10)
                            <li class="text-muted">+ {{ $role->permissions->count() - 10 }} autres...</li>
                        @endif
                    </ul>
                </div>
            @endforeach
        </div>
    </div>
</div>
@endsection

