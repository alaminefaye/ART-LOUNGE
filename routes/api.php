<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Les routes API pour l'application mobile et les intégrations externes
|
*/

// Routes publiques (pas d'authentification requise)
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/login-pin', [AuthController::class, 'loginWithPin']);
    Route::post('/login-pin-only', [AuthController::class, 'loginWithPinOnly']);
});

// Endpoints publics pour le menu via QR code (accessibles sans authentification)
Route::get('/tables/{id}/menu', [App\Http\Controllers\Api\TableController::class, 'getMenuForTable']);
// Endpoint pour récupérer les détails d'une table (public pour le scan QR)
Route::get('/tables/{id}', [App\Http\Controllers\Api\TableController::class, 'show']);

// Menu public - Consultation du menu (catégories et produits) sans authentification
Route::prefix('categories')->group(function () {
    Route::get('/', [App\Http\Controllers\Api\CategoryController::class, 'index']);
    Route::get('/{id}', [App\Http\Controllers\Api\CategoryController::class, 'show']);
});

Route::prefix('produits')->group(function () {
    Route::get('/', [App\Http\Controllers\Api\ProductController::class, 'index']);
    Route::get('/{id}', [App\Http\Controllers\Api\ProductController::class, 'show']);
});

// Tables - Routes publiques pour la consultation
Route::prefix('tables')->group(function () {
    // Liste des tables
    Route::get('/', [App\Http\Controllers\Api\TableController::class, 'index']);
    // Tables libres
    Route::get('/libres', [App\Http\Controllers\Api\TableController::class, 'libres']);
    // Détails d'une table (déjà public via QR code, mais on l'ajoute ici pour cohérence si besoin)
    // Route::get('/{id}', [App\Http\Controllers\Api\TableController::class, 'show']);
});

// Réservations - Vérification disponibilité publique
Route::post('/reservations/verifier-disponibilite', [App\Http\Controllers\Api\ReservationController::class, 'verifierDisponibilite']);

// Routes protégées (authentification requise)
Route::middleware('auth:sanctum')->group(function () {
    
    // Authentification
    Route::prefix('auth')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::post('/logout-all', [AuthController::class, 'logoutAll']);
        Route::post('/delete-account', [AuthController::class, 'deleteAccount']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/refresh', [AuthController::class, 'refresh']);
        Route::post('/fcm-token', [AuthController::class, 'updateFcmToken']);
        Route::put('/update-profile', [AuthController::class, 'updateProfile']);
        Route::put('/update-password', [AuthController::class, 'updatePassword']);
        Route::post('/set-pin', [AuthController::class, 'setPin']);
        Route::post('/verify-pin', [AuthController::class, 'verifyPin']);
        Route::get('/waiters', [AuthController::class, 'getWaiters']);
    });
    
    // ==========================================
    // DASHBOARD - Statistiques (Manager, Admin)
    // ==========================================
    Route::middleware('permission:view_dashboard')->group(function () {
        Route::get('/dashboard/stats', [App\Http\Controllers\Api\DashboardController::class, 'stats']);
    });
    
    // Route de test (à supprimer en production)
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // Notifications (liste, lu / non lu)
    Route::prefix('notifications')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\NotificationController::class, 'index']);
        Route::get('/unread-count', [App\Http\Controllers\Api\NotificationController::class, 'unreadCount']);
        Route::patch('/{id}/read', [App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);
        Route::post('/mark-all-read', [App\Http\Controllers\Api\NotificationController::class, 'markAllAsRead']);
    });
    
    // ==========================================
    // TABLES - Gestion des tables (Administration)
    // ==========================================
    Route::prefix('tables')->group(function () {
        // QR Code d'une table
        Route::get('/{id}/qrcode', [App\Http\Controllers\Api\TableController::class, 'getQRCode']);
        
        // Changer le statut (serveur, caissier, manager, admin)
        Route::patch('/{id}/statut', [App\Http\Controllers\Api\TableController::class, 'updateStatut'])
            ->middleware('permission:update_table_status');
        
        // CRUD complet (manager, admin uniquement)
        Route::middleware('permission:manage_tables')->group(function () {
            Route::post('/', [App\Http\Controllers\Api\TableController::class, 'store']);
            Route::put('/{id}', [App\Http\Controllers\Api\TableController::class, 'update']);
            Route::patch('/{id}', [App\Http\Controllers\Api\TableController::class, 'update']);
            Route::delete('/{id}', [App\Http\Controllers\Api\TableController::class, 'destroy']);
            Route::post('/{id}/regenerate-qrcode', [App\Http\Controllers\Api\TableController::class, 'regenerateQRCode']);
        });
    });
    
    // ==========================================
    // CATEGORIES - Gestion des catégories (CRUD protégé)
    // Note: GET est public (défini ci-dessus)
    // ==========================================
    Route::prefix('categories')->group(function () {
        // CRUD (manager, admin uniquement)
        Route::middleware('permission:manage_menu')->group(function () {
            Route::post('/', [App\Http\Controllers\Api\CategoryController::class, 'store']);
            Route::put('/{id}', [App\Http\Controllers\Api\CategoryController::class, 'update']);
            Route::patch('/{id}', [App\Http\Controllers\Api\CategoryController::class, 'update']);
            Route::delete('/{id}', [App\Http\Controllers\Api\CategoryController::class, 'destroy']);
        });
    });
    
    // ==========================================
    // PRODUITS - Gestion du menu (CRUD protégé)
    // Note: GET est public (défini ci-dessus)
    // ==========================================
    Route::prefix('produits')->group(function () {
        // CRUD (manager, admin uniquement)
        Route::middleware('permission:manage_menu')->group(function () {
            Route::post('/', [App\Http\Controllers\Api\ProductController::class, 'store']);
            Route::put('/{id}', [App\Http\Controllers\Api\ProductController::class, 'update']);
            Route::patch('/{id}', [App\Http\Controllers\Api\ProductController::class, 'update']);
            Route::delete('/{id}', [App\Http\Controllers\Api\ProductController::class, 'destroy']);
        });
    });
    
    // ==========================================
    // COMMANDES - Gestion des commandes
    // ==========================================
    Route::prefix('commandes')->group(function () {
        // Liste et détails
        Route::get('/', [App\Http\Controllers\Api\CommandeController::class, 'index'])
            ->middleware('permission:view_orders');
        Route::get('/{id}', [App\Http\Controllers\Api\CommandeController::class, 'show'])
            ->middleware('permission:view_orders');
        
        // Créer une commande (serveur, caissier, manager, admin)
        Route::post('/', [App\Http\Controllers\Api\CommandeController::class, 'store'])
            ->middleware('permission:create_orders');
        
        // Modifier une commande (serveur, manager, admin) et clients (leurs propres commandes)
        Route::middleware('permission:update_orders')->group(function () {
            Route::put('/{id}', [App\Http\Controllers\Api\CommandeController::class, 'update']);
            Route::patch('/{id}', [App\Http\Controllers\Api\CommandeController::class, 'update']);
            Route::post('/{id}/produits', [App\Http\Controllers\Api\CommandeController::class, 'addProduit']);
            Route::delete('/{id}/produits/{produitId}', [App\Http\Controllers\Api\CommandeController::class, 'removeProduit']);
        });
        
        // Lancer une commande (client peut lancer sa propre commande)
        Route::post('/{id}/lancer', [App\Http\Controllers\Api\CommandeController::class, 'lancer'])
            ->middleware('permission:update_orders');
        
        // Marquer les produits non servis comme servis (bouton Servi)
        Route::post('/{id}/marquer-servi', [App\Http\Controllers\Api\CommandeController::class, 'marquerServi'])
            ->middleware('permission:update_orders,update_order_status');
        
        // Récupérer la facture d'une commande (client peut voir sa facture, gérant peut toutes)
        Route::get('/{id}/facture', [App\Http\Controllers\Api\CommandeController::class, 'getFacture'])
            ->middleware('permission:view_orders');
        
        // Changer le statut (serveur, caissier, manager, admin uniquement - pas les clients)
        Route::patch('/{id}/statut', [App\Http\Controllers\Api\CommandeController::class, 'updateStatut'])
            ->middleware('permission:update_orders,update_order_status');
    });
    
    // ==========================================
    // PAIEMENTS - Gestion des paiements & factures
    // ==========================================
    Route::prefix('paiements')->group(function () {
        // Liste et détails (caissier, manager, admin)
        Route::get('/', [App\Http\Controllers\Api\PaiementController::class, 'index'])
            ->middleware('permission:view_cashier');
        Route::get('/{paiement}', [App\Http\Controllers\Api\PaiementController::class, 'show'])
            ->middleware('permission:view_cashier');
        
        // Initier un paiement (client pour Wave/Orange Money, gérant pour tous)
        Route::post('/', [App\Http\Controllers\Api\PaiementController::class, 'store'])
            ->middleware('permission:create_orders,process_payments');
        
        // Workflow rapide paiement espèces (caissier, manager, admin uniquement)
        Route::post('/especes', [App\Http\Controllers\Api\PaiementController::class, 'payerEspeces'])
            ->middleware('permission:process_payments');
        
        // Client confirme son paiement mobile money (Wave, Orange Money)
        Route::post('/{paiement}/confirmer', [App\Http\Controllers\Api\PaiementController::class, 'confirmer'])
            ->middleware('permission:create_orders,process_payments');
        
        // Valider un paiement mobile money (caissier, manager, admin uniquement)
        Route::patch('/{paiement}/valider', [App\Http\Controllers\Api\PaiementController::class, 'valider'])
            ->middleware('permission:process_payments');
        
        // Marquer comme échoué (caissier, manager, admin)
        Route::patch('/{paiement}/echouer', [App\Http\Controllers\Api\PaiementController::class, 'echouer'])
            ->middleware('permission:process_payments');
        
        // Annuler un paiement (caissier, manager, admin)
        Route::delete('/{paiement}', [App\Http\Controllers\Api\PaiementController::class, 'annuler'])
            ->middleware('permission:process_payments');
        
        // Télécharger la facture (client peut télécharger sa facture, gérant peut toutes)
        Route::get('/{paiement}/facture', [App\Http\Controllers\Api\PaiementController::class, 'telechargerFacture'])
            ->middleware('permission:create_orders,generate_invoices');
    });

    // ==========================================
    // SESSIONS DE CAISSE - Gestion des shifts
    // ==========================================
    Route::prefix('caisse/sessions')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\CaisseSessionController::class, 'index'])
            ->middleware('permission:manage_sessions');
        Route::get('/current', [App\Http\Controllers\Api\CaisseSessionController::class, 'current'])
            ->middleware('permission:manage_sessions');
        Route::post('/ouvrir', [App\Http\Controllers\Api\CaisseSessionController::class, 'ouvrir'])
            ->middleware('permission:manage_sessions');
        Route::get('/bilan', [App\Http\Controllers\Api\CaisseSessionController::class, 'bilan'])
            ->middleware('permission:manage_sessions');
        Route::post('/fermer', [App\Http\Controllers\Api\CaisseSessionController::class, 'fermer'])
            ->middleware('permission:manage_sessions');
    });

    // ==========================================
    // AVIS - Notes & commentaires (clients + staff)
    // ==========================================
    Route::prefix('avis')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\AvisController::class, 'index']);
        Route::get('/commande/{commandeId}', [App\Http\Controllers\Api\AvisController::class, 'showForCommande']);
        Route::post('/', [App\Http\Controllers\Api\AvisController::class, 'store']);
    });
    
    // ==========================================
    // CLIENTS - Fidélité & Recherche
    // ==========================================
    Route::prefix('clients')->group(function () {
        Route::get('/search', [App\Http\Controllers\Api\ClientController::class, 'search'])
            ->middleware('permission:view_orders,process_payments');
    });

    // ==========================================
    // RESERVATIONS - Gestion des réservations de tables
    // ==========================================
    Route::prefix('reservations')->group(function () {
        // Liste des réservations
        Route::get('/', [App\Http\Controllers\Api\ReservationController::class, 'index']);
        
        // Créer une réservation
        Route::post('/', [App\Http\Controllers\Api\ReservationController::class, 'store']);
        
        // Détails d'une réservation
        Route::get('/{id}', [App\Http\Controllers\Api\ReservationController::class, 'show']);
        
        // Confirmer une réservation (manager, admin uniquement)
        Route::patch('/{id}/confirmer', [App\Http\Controllers\Api\ReservationController::class, 'confirmer'])
            ->middleware('permission:manage_reservations');
        
        // Annuler une réservation (client peut annuler ses propres réservations, manager/admin peuvent toutes)
        Route::patch('/{id}/annuler', [App\Http\Controllers\Api\ReservationController::class, 'annuler']);
    });
});
