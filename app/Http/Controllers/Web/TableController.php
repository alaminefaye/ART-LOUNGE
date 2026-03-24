<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Table;
use App\Enums\TableType;
use App\Enums\TableStatus;
use App\Services\QRCodeService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TableController extends Controller
{
    protected $qrCodeService;
    
    public function __construct(QRCodeService $qrCodeService)
    {
        $this->qrCodeService = $qrCodeService;
    }
    
    public function index(Request $request)
    {
        $stats = [
            'total' => Table::count(),
            'libres' => Table::where('statut', TableStatus::Libre)->count(),
            'occupees' => Table::where('statut', TableStatus::Occupee)->count(),
            'reservees' => Table::where('statut', TableStatus::Reservee)->count(),
        ];

        $query = Table::query()->orderBy('numero');

        if ($request->filled('search')) {
            $term = $request->string('search')->trim();
            $query->where('numero', 'like', '%'.$term.'%');
        }
        if ($request->filled('type')) {
            $query->where('type', $request->input('type'));
        }
        if ($request->filled('statut')) {
            $query->where('statut', $request->input('statut'));
        }

        $tables = $query->paginate(10)->withQueryString();

        return view('tables.index', compact('tables', 'stats'));
    }
    
    public function create()
    {
        $types = TableType::cases();
        return view('tables.create', compact('types'));
    }
    
    public function store(Request $request)
    {
        $validated = $request->validate([
            'numero' => 'required|string|unique:tables,numero',
            'type' => ['required', Rule::enum(TableType::class)],
            'capacite' => 'required|integer|min:1',
            'prix' => 'nullable|numeric|min:0',
            'prix_par_heure' => 'nullable|numeric|min:0',
        ]);
        
        $table = Table::create($validated);
        
        // Generate QR Code
        $qrCodePath = $this->qrCodeService->generateForTable($table);
        $table->qr_code = $qrCodePath;
        $table->save();
        
        return redirect()->route('tables.index')
                        ->with('success', 'Table créée avec succès !');
    }
    
    public function show(Table $table)
    {
        $table->load('commandes');
        return view('tables.show', compact('table'));
    }
    
    public function edit(Table $table)
    {
        $types = TableType::cases();
        $statuts = TableStatus::cases();
        return view('tables.edit', compact('table', 'types', 'statuts'));
    }
    
    public function update(Request $request, Table $table)
    {
        $validated = $request->validate([
            'numero' => ['required', 'string', Rule::unique('tables')->ignore($table->id)],
            'type' => ['required', Rule::enum(TableType::class)],
            'capacite' => 'required|integer|min:1',
            'prix' => 'nullable|numeric|min:0',
            'prix_par_heure' => 'nullable|numeric|min:0',
            'statut' => ['required', Rule::enum(TableStatus::class)],
        ]);
        
        $table->update($validated);
        
        return redirect()->route('tables.index')
                        ->with('success', 'Table modifiée avec succès !');
    }
    
    public function destroy(Table $table)
    {
        // Delete QR code file using service
        $this->qrCodeService->deleteForTable($table);
        
        $table->delete();
        
        return redirect()->route('tables.index')
                        ->with('success', 'Table supprimée avec succès !');
    }
    
    public function regenerateQr(Table $table)
    {
        // Regenerate QR code using service
        $qrCodePath = $this->qrCodeService->regenerateForTable($table);
        $table->qr_code = $qrCodePath;
        $table->save();
        
        return back()->with('success', 'QR Code régénéré avec succès !');
    }
}
