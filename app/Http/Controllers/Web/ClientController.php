<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Client;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ClientController extends Controller
{
    public function index()
    {
        $clients = Client::orderBy('points_fidelite', 'desc')->paginate(10);
        return view('clients.index', compact('clients'));
    }

    public function create()
    {
        return view('clients.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'required|string|max:255',
            'telephone' => 'required|string|max:20|unique:clients',
            'email' => 'nullable|email|unique:clients',
            'date_naissance' => 'nullable|date',
            'adresse' => 'nullable|string',
        ]);

        $validated['date_inscription'] = now();

        Client::create($validated);

        return redirect()->route('clients.index')
                        ->with('success', 'Client créé avec succès !');
    }

    public function show(Client $client)
    {
        $client->load('historiquePoints');
        return view('clients.show', compact('client'));
    }

    public function edit(Client $client)
    {
        return view('clients.edit', compact('client'));
    }

    public function update(Request $request, Client $client)
    {
        $validated = $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'required|string|max:255',
            'telephone' => ['required', 'string', 'max:20', Rule::unique('clients')->ignore($client->id)],
            'email' => ['nullable', 'email', Rule::unique('clients')->ignore($client->id)],
            'date_naissance' => 'nullable|date',
            'adresse' => 'nullable|string',
            'actif' => 'boolean',
        ]);

        $validated['actif'] = $request->has('actif');

        $client->update($validated);

        return redirect()->route('clients.index')
                        ->with('success', 'Client modifié avec succès !');
    }

    public function destroy(Client $client)
    {
        $client->delete();

        return redirect()->route('clients.index')
                        ->with('success', 'Client supprimé avec succès !');
    }

    /**
     * Ajuster les points manuellement
     */
    public function ajusterPoints(Request $request, Client $client)
    {
        $validated = $request->validate([
            'points' => 'required|integer',
            'description' => 'required|string|max:255',
        ]);

        if ($validated['points'] > 0) {
            $client->ajouterPoints($validated['points'], $validated['description']);
        } else {
            $client->retirerPoints(abs($validated['points']), $validated['description']);
        }

        return back()->with('success', 'Points ajustés avec succès !');
    }
}

