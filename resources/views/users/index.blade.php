@extends('layouts.app')
@section('title', 'Utilisateurs')
@section('content')
<div class="card">
    <div class="card-header d-flex justify-content-between">
        <h5 class="mb-0">👥 Utilisateurs</h5>
        @can('manage_users')
            <a href="{{ route('users.create') }}" class="btn btn-primary"><i class="bx bx-plus"></i> Nouvel Utilisateur</a>
        @endcan
    </div>
    <div class="card-body">
        <table class="table">
            <thead>
                <tr>
                    <th>Nom</th>
                    <th>Email</th>
                    <th>Rôles</th>
                    <th>Créé le</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($users as $user)
                <tr>
                    <td><strong>{{ $user->name }}</strong></td>
                    <td>{{ $user->email }}</td>
                    <td>
                        @foreach($user->roles as $role)
                            <span class="badge bg-{{ $role->name === 'admin' ? 'danger' : ($role->name === 'manager' ? 'warning' : 'secondary') }}">
                                {{ ucfirst($role->name) }}
                            </span>
                        @endforeach
                    </td>
                    <td>{{ $user->created_at->format('d/m/Y') }}</td>
                    <td>
                        <a href="{{ route('users.show', $user) }}" class="btn btn-sm btn-info" title="Voir"><i class="bx bx-show"></i></a>
                        @can('manage_users')
                            <a href="{{ route('users.edit', $user) }}" class="btn btn-sm btn-warning" title="Modifier"><i class="bx bx-edit"></i></a>
                            @if($user->id !== auth()->id())
                                <form action="{{ route('users.destroy', $user) }}" method="POST" style="display:inline;" onsubmit="return confirm('Supprimer cet utilisateur ?')">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="btn btn-sm btn-danger" title="Supprimer"><i class="bx bx-trash"></i></button>
                                </form>
                            @endif
                        @endcan
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" class="text-center text-muted">Aucun utilisateur trouvé</td>
                </tr>
                @endforelse
            </tbody>
        </table>
        
        <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-3 mt-3 pt-3 border-top">
            <div class="text-muted small">
                @if($users->total() > 0)
                    Affichage de <strong>{{ $users->firstItem() }}</strong> à <strong>{{ $users->lastItem() }}</strong>
                    sur <strong>{{ $users->total() }}</strong> utilisateur(s)
                @endif
            </div>
            {{ $users->links() }}
        </div>
    </div>
</div>
@endsection

