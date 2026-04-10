@extends('layouts.app')

@section('title', 'Gestion des Serveurs')

@section('content')
<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">Liste des Serveurs</h5>
                <a href="{{ route('serveurs.create') }}" class="btn btn-primary">
                    <i class="bx bx-plus me-1"></i> Ajouter un Surveur
                </a>
            </div>
            <div class="table-responsive text-nowrap">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>Nom</th>
                            <th>Prénom</th>
                            <th>Téléphone</th>
                            <th>Statut</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody class="table-border-bottom-0">
                        @forelse($serveurs as $serveur)
                        <tr>
                            <td><strong>{{ $serveur->nom }}</strong></td>
                            <td>{{ $serveur->prenom ?? '-' }}</td>
                            <td>{{ $serveur->telephone ?? '-' }}</td>
                            <td>
                                @if($serveur->actif)
                                    <span class="badge bg-label-success">Actif</span>
                                @else
                                    <span class="badge bg-label-danger">Inactif</span>
                                @endif
                            </td>
                            <td>
                                <div class="dropdown">
                                    <button type="button" class="btn p-0 dropdown-toggle hide-arrow" data-bs-toggle="dropdown">
                                        <i class="bx bx-dots-vertical-rounded"></i>
                                    </button>
                                    <div class="dropdown-menu">
                                        <a class="dropdown-item" href="{{ route('serveurs.edit', $serveur) }}">
                                            <i class="bx bx-edit-alt me-1"></i> Modifier
                                        </a>
                                        <form action="{{ route('serveurs.destroy', $serveur) }}" method="POST" onsubmit="return confirm('Êtes-vous sûr ?');">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="dropdown-item text-danger">
                                                <i class="bx bx-trash me-1"></i> Supprimer
                                            </button>
                                        </form>
                                    </div>
                                </div>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="5" class="text-center">Aucun serveur trouvé</td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection
