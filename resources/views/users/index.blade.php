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
        @can('manage_users')
        <div class="alert alert-info py-2 small mb-3" role="status">
            Colonne <strong>PIN</strong> : <strong>Afficher</strong> / <strong>Masquer</strong> le code.
            Si un utilisateur a été créé <em>avant</em> la mise à jour, ouvrez <strong>Modifier</strong> et saisissez à nouveau son PIN (4 chiffres) une fois pour activer l’affichage.
        </div>
        @endcan
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
                                <div class="d-flex align-items-center gap-1 flex-wrap">
                                    <span class="pin-masked font-monospace" style="min-width:4ch;letter-spacing:0.2em">••••</span>
                                    @if($pinPlain !== null)
                                        <span class="pin-reveal d-none font-monospace user-select-all">{{ $pinPlain }}</span>
                                    @else
                                        <span class="pin-reveal d-none small text-muted" style="max-width:220px;line-height:1.3">
                                            PIN non disponible à l’affichage (créé avant la mise à jour ou colonne absente).
                                            Ouvrez <strong>Modifier</strong>, saisissez à nouveau les 4 chiffres, enregistrez — puis l’affichage fonctionnera.
                                        </span>
                                    @endif
                                    <button type="button" class="btn btn-sm btn-outline-primary btn-pin-toggle"
                                            data-label-show="Afficher" data-label-hide="Masquer">Afficher</button>
                                </div>
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
<script>
document.querySelectorAll('.btn-pin-toggle').forEach(function (btn) {
    btn.addEventListener('click', function () {
        const wrap = btn.closest('div');
        if (!wrap) return;
        const masked = wrap.querySelector('.pin-masked');
        const reveal = wrap.querySelector('.pin-reveal');
        if (!masked || !reveal) return;
        const isHidden = reveal.classList.contains('d-none');
        if (isHidden) {
            reveal.classList.remove('d-none');
            masked.classList.add('d-none');
            btn.textContent = btn.dataset.labelHide;
        } else {
            reveal.classList.add('d-none');
            masked.classList.remove('d-none');
            btn.textContent = btn.dataset.labelShow;
        }
    });
});
</script>
@endsection

