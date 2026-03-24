@extends('layouts.app')
@section('title', 'Rôles & Permissions')
@section('content')
<div class="card">
    <div class="card-header d-flex justify-content-between">
        <h5 class="mb-0">🔐 Rôles & Permissions</h5>
        @can('manage_roles')
            <a href="{{ route('roles.create') }}" class="btn btn-primary"><i class="bx bx-plus"></i> Nouveau Rôle</a>
        @endcan
    </div>
    <div class="card-body">
        <div class="row">
            @forelse($roles as $role)
            <div class="col-md-6 col-lg-4 mb-3">
                <div class="card border-start border-{{ $role->name === 'admin' ? 'danger' : ($role->name === 'manager' ? 'warning' : 'secondary') }} border-3">
                    <div class="card-body">
                        <h5 class="card-title text-{{ $role->name === 'admin' ? 'danger' : ($role->name === 'manager' ? 'warning' : 'dark') }}">
                            {{ ucfirst($role->name) }}
                        </h5>
                        <p class="card-text">
                            <small class="text-muted">
                                <i class="bx bx-shield"></i> {{ $role->permissions_count }} permission(s)<br>
                                <i class="bx bx-user"></i> {{ $role->users_count }} utilisateur(s)
                            </small>
                        </p>
                        <div class="d-flex gap-2">
                            <a href="{{ route('roles.show', $role) }}" class="btn btn-sm btn-info">
                                <i class="bx bx-show"></i> Voir
                            </a>
                            @can('manage_roles')
                                <a href="{{ route('roles.edit', $role) }}" class="btn btn-sm btn-warning">
                                    <i class="bx bx-edit"></i>
                                </a>
                                @if($role->name !== 'admin')
                                    <form action="{{ route('roles.destroy', $role) }}" method="POST" style="display:inline;" onsubmit="return confirm('Supprimer ce rôle ?')">
                                        @csrf @method('DELETE')
                                        <button type="submit" class="btn btn-sm btn-danger"><i class="bx bx-trash"></i></button>
                                    </form>
                                @endif
                            @endcan
                        </div>
                    </div>
                </div>
            </div>
            @empty
            <div class="col-12 text-center text-muted py-4">Aucun rôle</div>
            @endforelse
        </div>

        <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-3 mt-3 pt-3 border-top">
            <div class="text-muted small">
                @if($roles->total() > 0)
                    Affichage de <strong>{{ $roles->firstItem() }}</strong> à <strong>{{ $roles->lastItem() }}</strong>
                    sur <strong>{{ $roles->total() }}</strong> rôle(s)
                @endif
            </div>
            {{ $roles->links() }}
        </div>
    </div>
</div>
@endsection

