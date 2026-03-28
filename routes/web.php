<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Web\TableController;
use App\Http\Controllers\Web\MenuController;
use App\Http\Controllers\Web\CommandeController;
use App\Http\Controllers\Web\PaiementController;
use App\Http\Controllers\Web\AvisController;
use App\Http\Controllers\Web\CaisseSessionController;
use App\Http\Controllers\ReportController;

// Authentication Routes
Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
Route::post('/login', [LoginController::class, 'login']);
Route::post('/logout', [LoginController::class, 'logout'])->name('logout');

// Protected Routes
Route::middleware(['auth'])->group(function () {
    
    // Dashboard
    Route::middleware(['can:view_dashboard'])->group(function () {
        Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
        Route::get('/dashboard', [DashboardController::class, 'index']);
    });
    
    // Tables
    Route::middleware(['can:view_tables'])->group(function () {
        Route::middleware(['can:manage_tables'])->group(function () {
            Route::get('tables/create', [TableController::class, 'create'])->name('tables.create');
            Route::post('tables', [TableController::class, 'store'])->name('tables.store');
        });

        Route::get('tables', [TableController::class, 'index'])->name('tables.index');
        Route::get('tables/{table}', [TableController::class, 'show'])->name('tables.show');
        
        Route::middleware(['can:manage_tables'])->group(function () {
            Route::get('tables/{table}/edit', [TableController::class, 'edit'])->name('tables.edit');
            Route::put('tables/{table}', [TableController::class, 'update'])->name('tables.update');
            Route::delete('tables/{table}', [TableController::class, 'destroy'])->name('tables.destroy');
            Route::post('tables/{table}/regenerate-qr', [TableController::class, 'regenerateQr'])->name('tables.regenerate-qr');
        });
    });
    
    // Réservations
    Route::middleware(['can:view_reservations'])->group(function () {
        Route::middleware(['can:manage_reservations'])->group(function () {
            Route::get('reservations/create', [\App\Http\Controllers\Web\ReservationController::class, 'create'])->name('reservations.create');
            Route::post('reservations', [\App\Http\Controllers\Web\ReservationController::class, 'store'])->name('reservations.store');
        });

        Route::get('reservations', [\App\Http\Controllers\Web\ReservationController::class, 'index'])->name('reservations.index');
        Route::get('reservations/{reservation}', [\App\Http\Controllers\Web\ReservationController::class, 'show'])->name('reservations.show');
        
        Route::middleware(['can:manage_reservations'])->group(function () {
            Route::get('reservations/{reservation}/edit', [\App\Http\Controllers\Web\ReservationController::class, 'edit'])->name('reservations.edit');
            Route::put('reservations/{reservation}', [\App\Http\Controllers\Web\ReservationController::class, 'update'])->name('reservations.update');
            Route::delete('reservations/{reservation}', [\App\Http\Controllers\Web\ReservationController::class, 'destroy'])->name('reservations.destroy');
            Route::post('reservations/{reservation}/confirm', [\App\Http\Controllers\Web\ReservationController::class, 'confirm'])->name('reservations.confirm');
            Route::post('reservations/{reservation}/cancel', [\App\Http\Controllers\Web\ReservationController::class, 'cancel'])->name('reservations.cancel');
        });
    });

    // Menu - Categories & Products
    Route::prefix('menu')->name('menu.')->group(function () {
        Route::middleware(['can:view_menu'])->group(function () {
            Route::get('categories', [MenuController::class, 'categoriesIndex'])->name('categories.index');
            Route::get('products', [MenuController::class, 'productsIndex'])->name('products.index');
            
            Route::middleware(['can:manage_menu'])->group(function () {
                Route::get('categories/create', [MenuController::class, 'categoriesCreate'])->name('categories.create');
                Route::post('categories', [MenuController::class, 'categoriesStore'])->name('categories.store');
                Route::get('categories/{category}/edit', [MenuController::class, 'categoriesEdit'])->name('categories.edit');
                Route::put('categories/{category}', [MenuController::class, 'categoriesUpdate'])->name('categories.update');
                Route::delete('categories/{category}', [MenuController::class, 'categoriesDestroy'])->name('categories.destroy');
                
                Route::get('products/create', [MenuController::class, 'productsCreate'])->name('products.create');
                Route::post('products', [MenuController::class, 'productsStore'])->name('products.store');
                Route::get('products/{product}/edit', [MenuController::class, 'productsEdit'])->name('products.edit');
                Route::put('products/{product}', [MenuController::class, 'productsUpdate'])->name('products.update');
                Route::delete('products/{product}', [MenuController::class, 'productsDestroy'])->name('products.destroy');
                Route::post('products/{product}/toggle', [MenuController::class, 'toggleAvailability'])->name('products.toggle');
            });
        });
    });
    
    // Commandes
    Route::middleware(['can:view_orders'])->group(function () {
        Route::middleware(['can:create_orders'])->group(function () {
            Route::get('commandes/create', [CommandeController::class, 'create'])->name('commandes.create');
            Route::post('commandes', [CommandeController::class, 'store'])->name('commandes.store');
        });

        Route::get('commandes', [CommandeController::class, 'index'])->name('commandes.index');
        Route::get('commandes/{commande}', [CommandeController::class, 'show'])->name('commandes.show');
        
        Route::middleware(['can:update_orders'])->group(function () {
            Route::get('commandes/{commande}/edit', [CommandeController::class, 'edit'])->name('commandes.edit');
            Route::put('commandes/{commande}', [CommandeController::class, 'update'])->name('commandes.update');
            Route::post('commandes/{commande}/add-product', [CommandeController::class, 'addProduct'])->name('commandes.add-product');
            Route::delete('commandes/{commande}/remove-product/{product}', [CommandeController::class, 'removeProduct'])->name('commandes.remove-product');
        });

        Route::patch('commandes/{commande}/status', [CommandeController::class, 'updateStatus'])
            ->name('commandes.update-status')
            ->middleware('can:update_order_status');
            
        Route::delete('commandes/{commande}', [CommandeController::class, 'destroy'])
            ->name('commandes.destroy')
            ->middleware('can:cancel_orders');
    });
    
    // Caisse & Paiements
    Route::middleware(['can:access_cashier'])->group(function () {
        Route::get('caisse', [PaiementController::class, 'caisse'])->name('caisse.index');
        Route::get('caisse/{commande}/payer', [PaiementController::class, 'payer'])->name('caisse.payer');
        Route::post('caisse/{commande}/traiter', [PaiementController::class, 'traiterPaiement'])->name('caisse.traiter');
        Route::get('caisse/facture/{facture}', [PaiementController::class, 'afficherFacture'])->name('caisse.facture');
        Route::get('caisse/facture/{facture}/telecharger', [PaiementController::class, 'telechargerFacture'])->name('caisse.facture.telecharger');
        Route::get('caisse/historique', [PaiementController::class, 'historique'])->name('caisse.historique');

        // Sessions de Caisse
        Route::prefix('caisse/sessions')->name('caisse.sessions.')->group(function () {
            Route::get('/', [CaisseSessionController::class, 'index'])->name('index');
            Route::post('/ouvrir', [CaisseSessionController::class, 'ouvrir'])->name('ouvrir');
            Route::get('/bilan', [CaisseSessionController::class, 'bilan'])->name('bilan');
            Route::post('/fermer', [CaisseSessionController::class, 'fermer'])->name('fermer');
        });
    });

    // Avis & Rapports
    Route::get('avis', [AvisController::class, 'index'])->name('avis.index')->middleware('can:view_avis');
    Route::get('rapport', [ReportController::class, 'index'])->name('rapport.index')->middleware('can:view_reports');
    
    // Rôles & Permissions
    Route::middleware(['can:view_roles'])->group(function () {
        Route::get('roles', [\App\Http\Controllers\Web\RoleController::class, 'index'])->name('roles.index');
        Route::get('roles/{role}', [\App\Http\Controllers\Web\RoleController::class, 'show'])->name('roles.show');
        
        Route::middleware(['can:manage_roles'])->group(function () {
            Route::get('roles/create', [\App\Http\Controllers\Web\RoleController::class, 'create'])->name('roles.create');
            Route::post('roles', [\App\Http\Controllers\Web\RoleController::class, 'store'])->name('roles.store');
            Route::get('roles/{role}/edit', [\App\Http\Controllers\Web\RoleController::class, 'edit'])->name('roles.edit');
            Route::put('roles/{role}', [\App\Http\Controllers\Web\RoleController::class, 'update'])->name('roles.update');
            Route::delete('roles/{role}', [\App\Http\Controllers\Web\RoleController::class, 'destroy'])->name('roles.destroy');
        });
    });
    
    // Utilisateurs (Staff)
    Route::middleware(['can:view_users'])->group(function () {
        Route::get('users', [\App\Http\Controllers\Web\UserController::class, 'index'])->name('users.index');
        Route::get('users/{user}', [\App\Http\Controllers\Web\UserController::class, 'show'])->name('users.show');
        
        Route::middleware(['can:manage_users'])->group(function () {
            Route::get('users/create', [\App\Http\Controllers\Web\UserController::class, 'create'])->name('users.create');
            Route::post('users', [\App\Http\Controllers\Web\UserController::class, 'store'])->name('users.store');
            Route::get('users/{user}/edit', [\App\Http\Controllers\Web\UserController::class, 'edit'])->name('users.edit');
            Route::put('users/{user}', [\App\Http\Controllers\Web\UserController::class, 'update'])->name('users.update');
            Route::delete('users/{user}', [\App\Http\Controllers\Web\UserController::class, 'destroy'])->name('users.destroy');
        });
    });
    
    // Clients & Fidélité
    Route::middleware(['can:view_customers'])->group(function () {
        Route::resource('clients', \App\Http\Controllers\Web\ClientController::class);
        
        Route::middleware(['can:manage_loyalty'])->group(function () {
            Route::post('clients/{client}/ajuster-points', [\App\Http\Controllers\Web\ClientController::class, 'ajusterPoints'])->name('clients.ajuster-points');
            Route::get('fidelity', [\App\Http\Controllers\Web\FidelitySettingController::class, 'edit'])->name('fidelity.edit');
            Route::put('fidelity', [\App\Http\Controllers\Web\FidelitySettingController::class, 'update'])->name('fidelity.update');
        });

        Route::middleware(['can:manage_payment_methods'])->group(function () {
            Route::get('payment-methods', [\App\Http\Controllers\Web\PaymentMethodSettingController::class, 'edit'])->name('payment-methods.edit');
            Route::put('payment-methods', [\App\Http\Controllers\Web\PaymentMethodSettingController::class, 'update'])->name('payment-methods.update');
        });
    });
});
