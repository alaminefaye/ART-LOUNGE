<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Avis;
use Illuminate\Http\Request;

class AvisController extends Controller
{
    public function index(Request $request)
    {
        $query = Avis::query()->with(['user', 'commande.table'])->orderByDesc('created_at');

        if ($request->filled('note')) {
            $query->where('note', (int) $request->query('note'));
        }

        $avis = $query->paginate(10)->withQueryString();

        $statsQuery = Avis::query();
        $moyenne = (float) $statsQuery->avg('note');
        $total = (int) $statsQuery->count();

        $repartition = Avis::query()
            ->selectRaw('note, COUNT(*) as total')
            ->groupBy('note')
            ->orderByDesc('note')
            ->pluck('total', 'note')
            ->toArray();

        return view('avis.index', [
            'avis' => $avis,
            'moyenne' => $moyenne,
            'total' => $total,
            'repartition' => $repartition,
        ]);
    }
}

