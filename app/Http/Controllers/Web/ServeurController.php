<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Serveur;
use Illuminate\Http\Request;

class ServeurController extends Controller
{
    public function index()
    {
        $serveurs = Serveur::orderBy('nom')->get();
        return view('serveurs.index', compact('serveurs'));
    }

    public function create()
    {
        return view('serveurs.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'nullable|string|max:255',
            'telephone' => 'nullable|string|max:20',
            'actif' => 'boolean',
        ]);

        $validated['actif'] = $request->has('actif') ? true : false;

        Serveur::create($validated);

        return redirect()->route('serveurs.index')->with('success', 'Serveur ajouté avec succès.');
    }

    public function edit(Serveur $serveur)
    {
        return view('serveurs.edit', compact('serveur'));
    }

    public function update(Request $request, Serveur $serveur)
    {
        $validated = $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'nullable|string|max:255',
            'telephone' => 'nullable|string|max:20',
            'actif' => 'boolean',
        ]);

        $validated['actif'] = $request->has('actif') ? true : false;

        $serveur->update($validated);

        return redirect()->route('serveurs.index')->with('success', 'Serveur mis à jour avec succès.');
    }

    public function destroy(Serveur $serveur)
    {
        // On ne supprime pas si le serveur a des commandes, on le désactive
        if ($serveur->commandes()->count() > 0) {
            $serveur->update(['actif' => false]);
            return redirect()->route('serveurs.index')->with('success', 'Le serveur a été désactivé (il possède des commandes existantes).');
        }

        $serveur->delete();
        return redirect()->route('serveurs.index')->with('success', 'Serveur supprimé avec succès.');
    }
}
