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
                    <th>🔐 PIN</th>
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
                    <td>
                        @if($user->hasPin())
                            @can('manage_users')
                                @php $pinPlain = $user->pinPlainForAdmin(); @endphp
                                @if($pinPlain !== null)
                                    <div class="d-flex align-items-center gap-1 flex-wrap">
                                        <span class="pin-masked font-monospace" style="min-width:4ch;letter-spacing:0.2em">••••</span>
                                        <span class="pin-shown font-monospace d-none">{{ $pinPlain }}</span>
                                        <button type="button" class="btn btn-sm btn-outline-primary pin-toggle"
                                                data-label-show="Afficher" data-label-hide="Masquer">Afficher</button>
                                    </div>
                                @else
                                    <span class="badge bg-success" title="PIN défini (non affichable ici — créé avant l’enregistrement chiffré ou APP_KEY modifiée)">✓</span>
                                @endif
                            @else
                                <span class="badge bg-success">✅</span>
                            @endcan
                        @else
                            <span class="badge bg-light text-muted">—</span>
                        @endif
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
                    <td colspan="6" class="text-center text-muted">Aucun utilisateur trouvé</td>
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
@can('manage_users')
<script>
document.querySelectorAll('.pin-toggle').forEach(function (btn) {
    btn.addEventListener('click', function () {
        const wrap = btn.closest('div');
        if (!wrap) return;
        const masked = wrap.querySelector('.pin-masked');
        const shown = wrap.querySelector('.pin-shown');
        if (!masked || !shown) return;
        const isHidden = shown.classList.contains('d-none');
        if (isHidden) {
            shown.classList.remove('d-none');
            masked.classList.add('d-none');
            btn.textContent = btn.dataset.labelHide;
        } else {
            shown.classList.add('d-none');
            masked.classList.remove('d-none');
            btn.textContent = btn.dataset.labelShow;
        }
    });
});
</script>
@endcan
@endsection

