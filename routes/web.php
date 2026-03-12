<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Web\TableController;
use App\Http\Controllers\Web\MenuController;
use App\Http\Controllers\Web\CommandeController;
use App\Http\Controllers\Web\PaiementController;
use App\Http\Controllers\Web\AvisController;

// Authentication Routes
Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
Route::post('/login', [LoginController::class, 'login']);
Route::post('/logout', [LoginController::class, 'logout'])->name('logout');

// Protected Routes
Route::middleware(['auth'])->group(function () {
    // Dashboard
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard', [DashboardController::class, 'index']);
    
    // Tables
    Route::resource('tables', TableController::class);
    Route::post('tables/{table}/regenerate-qr', [TableController::class, 'regenerateQr'])
        ->name('tables.regenerate-qr');
    
    // Réservations
    Route::resource('reservations', \App\Http\Controllers\Web\ReservationController::class);
    Route::post('reservations/{reservation}/confirm', [\App\Http\Controllers\Web\ReservationController::class, 'confirm'])
        ->name('reservations.confirm');
    Route::post('reservations/{reservation}/cancel', [\App\Http\Controllers\Web\ReservationController::class, 'cancel'])
        ->name('reservations.cancel');

    // Menu - Categories & Products
    Route::prefix('menu')->name('menu.')->group(function () {
        // Categories
        Route::get('categories', [MenuController::class, 'categoriesIndex'])->name('categories.index');
        Route::get('categories/create', [MenuController::class, 'categoriesCreate'])->name('categories.create');
        Route::post('categories', [MenuController::class, 'categoriesStore'])->name('categories.store');
        Route::get('categories/{category}/edit', [MenuController::class, 'categoriesEdit'])->name('categories.edit');
        Route::put('categories/{category}', [MenuController::class, 'categoriesUpdate'])->name('categories.update');
        Route::delete('categories/{category}', [MenuController::class, 'categoriesDestroy'])->name('categories.destroy');
        
        // Products
        Route::get('products', [MenuController::class, 'productsIndex'])->name('products.index');
        Route::get('products/create', [MenuController::class, 'productsCreate'])->name('products.create');
        Route::post('products', [MenuController::class, 'productsStore'])->name('products.store');
        Route::get('products/{product}/edit', [MenuController::class, 'productsEdit'])->name('products.edit');
        Route::put('products/{product}', [MenuController::class, 'productsUpdate'])->name('products.update');
        Route::delete('products/{product}', [MenuController::class, 'productsDestroy'])->name('products.destroy');
        Route::post('products/{product}/toggle', [MenuController::class, 'toggleAvailability'])->name('products.toggle');
    });
    
    // Commandes
    Route::resource('commandes', CommandeController::class);
    Route::post('commandes/{commande}/add-product', [CommandeController::class, 'addProduct'])
        ->name('commandes.add-product');
    Route::delete('commandes/{commande}/remove-product/{product}', [CommandeController::class, 'removeProduct'])
        ->name('commandes.remove-product');
    Route::patch('commandes/{commande}/status', [CommandeController::class, 'updateStatus'])
        ->name('commandes.update-status');
    
    // Caisse
    Route::get('caisse', [PaiementController::class, 'caisse'])->name('caisse.index');
    Route::get('caisse/{commande}/payer', [PaiementController::class, 'payer'])->name('caisse.payer');
    Route::post('caisse/{commande}/traiter', [PaiementController::class, 'traiterPaiement'])->name('caisse.traiter');
    Route::get('caisse/facture/{facture}', [PaiementController::class, 'afficherFacture'])->name('caisse.facture');
    Route::get('caisse/facture/{facture}/telecharger', [PaiementController::class, 'telechargerFacture'])->name('caisse.facture.telecharger');
    Route::get('caisse/historique', [PaiementController::class, 'historique'])->name('caisse.historique');

    // Avis / Notes
    Route::middleware(['can:view_dashboard'])->group(function () {
        Route::get('avis', [AvisController::class, 'index'])->name('avis.index');
    });
    
    // Rôles & Permissions
    Route::middleware(['can:view_roles'])->group(function () {
        Route::resource('roles', \App\Http\Controllers\Web\RoleController::class);
    });
    
    // Utilisateurs (Staff)
    Route::middleware(['can:view_users'])->group(function () {
        Route::resource('users', \App\Http\Controllers\Web\UserController::class);
    });
    
    // Clients & Fidélité
    Route::middleware(['can:view_customers'])->group(function () {
        Route::resource('clients', \App\Http\Controllers\Web\ClientController::class);
        Route::post('clients/{client}/ajuster-points', [\App\Http\Controllers\Web\ClientController::class, 'ajusterPoints'])
            ->name('clients.ajuster-points')
            ->middleware('can:manage_loyalty');
        Route::get('fidelity', [\App\Http\Controllers\Web\FidelitySettingController::class, 'edit'])->name('fidelity.edit');
        Route::put('fidelity', [\App\Http\Controllers\Web\FidelitySettingController::class, 'update'])->name('fidelity.update');
        Route::get('payment-methods', [\App\Http\Controllers\Web\PaymentMethodSettingController::class, 'edit'])->name('payment-methods.edit');
        Route::put('payment-methods', [\App\Http\Controllers\Web\PaymentMethodSettingController::class, 'update'])->name('payment-methods.update');
    });
});
