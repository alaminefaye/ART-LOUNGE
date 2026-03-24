<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Reservation;
use App\Models\Table;
use App\Enums\ReservationStatus;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ReservationController extends Controller
{
    public function index()
    {
        $reservations = Reservation::with(['table', 'user'])
                            ->orderBy('date_reservation', 'desc')
                            ->orderBy('heure_debut', 'desc')
                            ->paginate(10);
        return view('reservations.index', compact('reservations'));
    }

    public function create()
    {
        $tables = Table::where('actif', true)->get();
        return view('reservations.create', compact('tables'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'table_id' => 'required|exists:tables,id',
            'nom_client' => 'required|string|max:255',
            'telephone' => 'required|string|max:20',
            'email' => 'nullable|email|max:255',
            'date_reservation' => 'required|date|after_or_equal:today',
            'heure_debut' => 'required|date_format:H:i',
            'duree' => 'required|integer|min:1|max:12',
            'nombre_personnes' => 'required|integer|min:1',
            'notes' => 'nullable|string',
        ]);

        // Calculate end time
        $heureDebut = Carbon::parse($validated['date_reservation'] . ' ' . $validated['heure_debut']);
        $heureFin = $heureDebut->copy()->addHours($validated['duree']);
        
        // Calculate price
        $table = Table::findOrFail($validated['table_id']);
        $prixParHeure = $table->prix_par_heure ?? 0;
        $prixFixe = $table->prix ?? 0;
        $prixTotal = $prixParHeure > 0 ? $prixParHeure * $validated['duree'] : $prixFixe;

        Reservation::create([
            'table_id' => $validated['table_id'],
            'user_id' => $request->user()->id, // Manager creating the reservation
            'nom_client' => $validated['nom_client'],
            'telephone' => $validated['telephone'],
            'email' => $validated['email'],
            'date_reservation' => $validated['date_reservation'],
            'heure_debut' => $validated['heure_debut'],
            'heure_fin' => $heureFin->format('H:i'),
            'duree' => $validated['duree'],
            'nombre_personnes' => $validated['nombre_personnes'],
            'prix_total' => $prixTotal,
            'statut' => ReservationStatus::Attente,
            'notes' => $validated['notes'],
        ]);

        return redirect()->route('reservations.index')
                        ->with('success', 'Réservation créée avec succès !');
    }

    public function show(Reservation $reservation)
    {
        $reservation->load(['table', 'user']);
        return view('reservations.show', compact('reservation'));
    }

    public function edit(Reservation $reservation)
    {
        $tables = Table::where('actif', true)->get();
        return view('reservations.edit', compact('reservation', 'tables'));
    }

    public function update(Request $request, Reservation $reservation)
    {
        $validated = $request->validate([
            'table_id' => 'required|exists:tables,id',
            'nom_client' => 'required|string|max:255',
            'telephone' => 'required|string|max:20',
            'email' => 'nullable|email|max:255',
            'date_reservation' => 'required|date',
            'heure_debut' => 'required|date_format:H:i',
            'duree' => 'required|integer|min:1|max:12',
            'nombre_personnes' => 'required|integer|min:1',
            'statut' => 'required',
            'notes' => 'nullable|string',
        ]);

        // Calculate end time
        $heureDebut = Carbon::parse($validated['date_reservation'] . ' ' . $validated['heure_debut']);
        $heureFin = $heureDebut->copy()->addHours($validated['duree']);
        
        // Recalculate price if needed (optional logic, keeping simple for now)
        // For update, we might want to keep original price or recalculate. 
        // Let's recalculate for consistency.
        $table = Table::findOrFail($validated['table_id']);
        $prixParHeure = $table->prix_par_heure ?? 0;
        $prixFixe = $table->prix ?? 0;
        $prixTotal = $prixParHeure > 0 ? $prixParHeure * $validated['duree'] : $prixFixe;

        $reservation->update([
            'table_id' => $validated['table_id'],
            'nom_client' => $validated['nom_client'],
            'telephone' => $validated['telephone'],
            'email' => $validated['email'],
            'date_reservation' => $validated['date_reservation'],
            'heure_debut' => $validated['heure_debut'],
            'heure_fin' => $heureFin->format('H:i'),
            'duree' => $validated['duree'],
            'nombre_personnes' => $validated['nombre_personnes'],
            'prix_total' => $prixTotal,
            'statut' => $validated['statut'],
            'notes' => $validated['notes'],
        ]);

        return redirect()->route('reservations.show', $reservation)
                        ->with('success', 'Réservation mise à jour avec succès !');
    }

    public function destroy(Reservation $reservation)
    {
        $reservation->delete();
        return redirect()->route('reservations.index')
                        ->with('success', 'Réservation supprimée avec succès !');
    }

    public function confirm(Reservation $reservation)
    {
        if ($reservation->statut !== ReservationStatus::Attente) {
            return back()->with('error', 'Seules les réservations en attente peuvent être confirmées.');
        }

        $reservation->confirmer();
        return back()->with('success', 'Réservation confirmée avec succès !');
    }

    public function cancel(Reservation $reservation)
    {
        $reservation->update(['statut' => ReservationStatus::Annulee]);
        return back()->with('success', 'Réservation annulée avec succès !');
    }
}
