<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Trajet;
use Illuminate\Http\Request;

class TrajetController extends Controller
{
    public function index()
    {
        $trajets = Trajet::query()
            ->orderByDesc('actif')
            ->orderBy('heure_depart')
            ->orderBy('depart')
            ->paginate(20);

        return view('trajets.index', compact('trajets'));
    }

    public function create()
    {
        return view('trajets.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'depart' => 'required|string|max:255',
            'destination' => 'required|string|max:255',
            'heure_depart' => 'required|date_format:H:i',
            'actif' => 'boolean',
        ]);

        Trajet::create([
            'depart' => trim($validated['depart']),
            'destination' => trim($validated['destination']),
            'heure_depart' => $validated['heure_depart'],
            'actif' => $request->boolean('actif'),
        ]);

        return redirect()
            ->route('trajets.index')
            ->with('success', 'Trajet ajouté. Il sera visible dans l’application.');
    }

    public function edit(Trajet $trajet)
    {
        return view('trajets.edit', compact('trajet'));
    }

    public function update(Request $request, Trajet $trajet)
    {
        $validated = $request->validate([
            'depart' => 'required|string|max:255',
            'destination' => 'required|string|max:255',
            'heure_depart' => 'required|date_format:H:i',
            'actif' => 'boolean',
        ]);

        $trajet->update([
            'depart' => trim($validated['depart']),
            'destination' => trim($validated['destination']),
            'heure_depart' => $validated['heure_depart'],
            'actif' => $request->boolean('actif'),
        ]);

        return redirect()
            ->route('trajets.index')
            ->with('success', 'Trajet mis à jour.');
    }

    public function destroy(Trajet $trajet)
    {
        $trajet->delete();

        return redirect()
            ->route('trajets.index')
            ->with('success', 'Trajet supprimé.');
    }
}
