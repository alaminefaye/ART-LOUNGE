@extends('layouts.app')
@section('title', 'Trajets')
@section('content')
<div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">🚌 Trajets</h5>
        <a href="{{ route('trajets.create') }}" class="btn btn-primary"><i class="bx bx-plus"></i> Ajouter</a>
    </div>
    <div class="card-body">
        @if(session('success'))
            <div class="alert alert-success">
                <i class="bx bx-check-circle"></i> {{ session('success') }}
            </div>
        @endif

        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Départ</th>
                        <th>Destination</th>
                        <th>Statut</th>
                        <th class="text-end">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($trajets as $trajet)
                        <tr>
                            <td><strong>{{ $trajet->depart }}</strong></td>
                            <td>{{ $trajet->destination }}</td>
                            <td>
                                @if($trajet->actif)
                                    <span class="badge bg-success">Actif</span>
                                @else
                                    <span class="badge bg-secondary">Inactif</span>
                                @endif
                            </td>
                            <td class="text-end">
                                <a href="{{ route('trajets.edit', $trajet) }}" class="btn btn-sm btn-warning"><i class="bx bx-edit"></i></a>
                                <form action="{{ route('trajets.destroy', $trajet) }}" method="POST" style="display:inline;" onsubmit="return confirm('Supprimer ce trajet ?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-sm btn-danger"><i class="bx bx-trash"></i></button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="text-center text-muted">Aucun trajet</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-3 mt-3 pt-3 border-top">
            <div class="text-muted small">
                @if($trajets->total() > 0)
                    Affichage de <strong>{{ $trajets->firstItem() }}</strong> à <strong>{{ $trajets->lastItem() }}</strong>
                    sur <strong>{{ $trajets->total() }}</strong> trajet(s)
                @else
                    Aucun trajet à afficher
                @endif
            </div>
            {{ $trajets->links() }}
        </div>
    </div>
</div>
@endsection
