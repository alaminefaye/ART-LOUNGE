<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Client;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class AuthController extends Controller
{
    /**
     * Inscription (Register)
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function register(Request $request)
    {
        try {
            $validated = $request->validate([
                'nom' => 'required|string|max:255',
                'prenom' => 'required|string|max:255',
                'telephone' => 'required|string|max:20|unique:clients,telephone',
                'email' => 'nullable|email|max:255',
                'password' => 'required|string|min:6|confirmed',
            ]);

            // Vérifier l'unicité de l'email si fourni
            $email = $validated['email'] ?? null;
            if (!empty($email)) {
                if (User::where('email', $email)->exists()) {
                    return response()->json([
                        'message' => 'Cet email est déjà utilisé',
                        'errors' => ['email' => ['Cet email est déjà utilisé']],
                    ], 422);
                }
                if (Client::where('email', $email)->exists()) {
                    return response()->json([
                        'message' => 'Cet email est déjà utilisé',
                        'errors' => ['email' => ['Cet email est déjà utilisé']],
                    ], 422);
                }
            }

            DB::beginTransaction();

            // Générer un email unique si non fourni
            $userEmail = $email;
            if (empty($userEmail)) {
                // Créer un email unique basé sur le téléphone
                $baseEmail = $validated['telephone'] . '@resto.local';
                $counter = 1;
                $userEmail = $baseEmail;
                
                // Vérifier que l'email n'existe pas déjà
                while (User::where('email', $userEmail)->exists()) {
                    $userEmail = $validated['telephone'] . '_' . $counter . '@resto.local';
                    $counter++;
                }
            }

            // Créer l'utilisateur (pour l'authentification)
            $user = User::create([
                'name' => trim($validated['nom'] . ' ' . $validated['prenom']),
                'email' => $userEmail,
                'phone' => $validated['telephone'],
                'password' => Hash::make($validated['password']),
            ]);

            // Créer le client (pour la fidélité) et le lier à l'utilisateur
            $client = Client::create([
                'user_id' => $user->id,
                'nom' => $validated['nom'],
                'prenom' => $validated['prenom'],
                'telephone' => $validated['telephone'],
                'email' => $email, // Peut être null
                'date_inscription' => now(),
            ]);

            // Créer ou récupérer le rôle "client" et l'attribuer à l'utilisateur
            // Utiliser le guard par défaut (généralement 'web' pour Spatie Permission)
            $clientRole = Role::firstOrCreate(
                ['name' => 'client', 'guard_name' => 'web'],
                [
                    'name' => 'client',
                    'guard_name' => 'web',
                ]
            );
            
            // Attribuer les permissions nécessaires au rôle client
            // Permissions pour les clients : créer, voir et modifier leurs propres commandes
            $permissions = [
                'create_orders',  // Créer des commandes
                'view_orders',    // Voir les commandes (leurs propres commandes)
                'update_orders',  // Modifier leurs propres commandes (ajouter des produits)
            ];
            
            foreach ($permissions as $permissionName) {
                $permission = Permission::firstOrCreate(
                    ['name' => $permissionName, 'guard_name' => 'web']
                );
                // Utiliser syncWithoutDetaching pour ne pas supprimer les autres permissions
                $clientRole->givePermissionTo($permission);
            }
            
            $user->assignRole($clientRole);
            
            // Recharger les rôles et permissions pour s'assurer qu'ils sont disponibles
            $user->load('roles.permissions');

            DB::commit();

            // Connecter automatiquement l'utilisateur après l'inscription
            $user->load('roles.permissions');
            $permissions = $user->getAllPermissions()->pluck('name')->toArray();
            $token = $user->createToken('auth_token', $permissions)->plainTextToken;

            $fidelitySettings = \App\Models\FidelitySetting::get();
            $paymentMethods = \App\Models\PaymentMethodSetting::get();

            return response()->json([
                'message' => 'Inscription réussie',
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'roles' => $user->roles->pluck('name'),
                    'permissions' => $permissions,
                ],
                'client' => [
                    'id' => $client->id,
                    'nom' => $client->nom,
                    'prenom' => $client->prenom,
                    'telephone' => $client->telephone,
                    'email' => $client->email,
                    'points_fidelite' => (int) $client->points_fidelite,
                ],
                'fidelity_settings' => [
                    'actif' => $fidelitySettings->actif,
                    'valeur_fcfa_1_point' => (float) $fidelitySettings->valeur_fcfa_1_point,
                ],
                'payment_method_settings' => [
                    'wave_enabled' => $paymentMethods->wave_enabled,
                    'orange_money_enabled' => $paymentMethods->orange_money_enabled,
                ],
                'token' => $token,
                'token_type' => 'Bearer',
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Erreur de validation',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            
            // Logger l'erreur pour le débogage
            Log::error('Erreur lors de l\'inscription: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'request' => $request->all(),
            ]);
            
            return response()->json([
                'message' => 'Erreur serveur. Veuillez réessayer plus tard.',
                'error' => config('app.debug') ? $e->getMessage() : 'Erreur interne du serveur',
            ], 500);
        }
    }

    /**
     * Connexion (Login)
     * Accepte soit un email soit un numéro de téléphone
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|string', // Peut être email ou téléphone
            'password' => 'required',
        ]);

        $identifier = $request->email;
        $user = null;

        // Vérifier si c'est un email (contient @)
        if (str_contains($identifier, '@')) {
            // Connexion par email
            $user = User::where('email', $identifier)->first();
        } else {
            // Connexion par téléphone
            // Chercher le client par téléphone
            $client = Client::where('telephone', $identifier)->first();
            
            if ($client) {
                // Si le client a un email, chercher le User par cet email
                if ($client->email) {
                    $user = User::where('email', $client->email)->first();
                }
                
                // Si pas trouvé, essayer avec l'email généré (telephone@resto.local)
                if (!$user) {
                    $generatedEmail = $identifier . '@resto.local';
                    $user = User::where('email', $generatedEmail)->first();
                    
                    // Si toujours pas trouvé, essayer avec les variantes (telephone_1@resto.local, etc.)
                    if (!$user) {
                        $counter = 1;
                        while (!$user && $counter < 10) {
                            $generatedEmail = $identifier . '_' . $counter . '@resto.local';
                            $user = User::where('email', $generatedEmail)->first();
                            $counter++;
                        }
                    }
                }
            }
        }

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Les identifiants fournis sont incorrects.'],
            ]);
        }

        // Charger les rôles et permissions
        $user->load('roles.permissions');

        // Créer un token avec les capacités (abilities) basées sur les permissions
        $permissions = $user->getAllPermissions()->pluck('name')->toArray();
        $token = $user->createToken('auth_token', $permissions)->plainTextToken;

        $client = $user->client;
        $fidelitySettings = \App\Models\FidelitySetting::get();
        $paymentMethods = \App\Models\PaymentMethodSetting::get();

        return response()->json([
            'message' => 'Connexion réussie',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'roles' => $user->roles->pluck('name'),
                'permissions' => $permissions,
            ],
            'client' => $client ? [
                'id' => $client->id,
                'nom' => $client->nom,
                'prenom' => $client->prenom,
                'points_fidelite' => (int) $client->points_fidelite,
            ] : null,
            'fidelity_settings' => [
                'actif' => $fidelitySettings->actif,
                'valeur_fcfa_1_point' => (float) $fidelitySettings->valeur_fcfa_1_point,
            ],
            'payment_method_settings' => [
                'wave_enabled' => $paymentMethods->wave_enabled,
                'orange_money_enabled' => $paymentMethods->orange_money_enabled,
            ],
            'token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    /**
     * Déconnexion (Logout)
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout(Request $request)
    {
        // Supprimer le token actuel
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Déconnexion réussie',
        ]);
    }

    /**
     * Supprimer tous les tokens de l'utilisateur
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logoutAll(Request $request)
    {
        // Supprimer tous les tokens de l'utilisateur
        $request->user()->tokens()->delete();

        return response()->json([
            'message' => 'Déconnexion de tous les appareils réussie',
        ]);
    }

    /**
     * Mettre à jour le token FCM pour les notifications
     */
    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = $request->user();
        $user->update(['fcm_token' => $request->fcm_token]);

        return response()->json([
            'success' => true,
            'message' => 'Token FCM mis à jour avec succès',
        ]);
    }

    /**
     * Obtenir les informations de l'utilisateur connecté
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function me(Request $request)
    {
        $user = $request->user();
        $user->load('roles.permissions', 'client');

        $client = $user->client;
        $fidelitySettings = \App\Models\FidelitySetting::get();
        $paymentMethods = \App\Models\PaymentMethodSetting::get();

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'email_verified_at' => $user->email_verified_at,
                'created_at' => $user->created_at,
                'roles' => $user->roles->map(function ($role) {
                    return [
                        'id' => $role->id,
                        'name' => $role->name,
                        'display_name' => $role->display_name,
                    ];
                }),
                'permissions' => $user->getAllPermissions()->map(function ($permission) {
                    return [
                        'id' => $permission->id,
                        'name' => $permission->name,
                        'display_name' => $permission->display_name,
                        'group' => $permission->group,
                    ];
                }),
            ],
            'client' => $client ? [
                'id' => $client->id,
                'nom' => $client->nom,
                'prenom' => $client->prenom,
                'points_fidelite' => (int) $client->points_fidelite,
            ] : null,
            'fidelity_settings' => [
                'actif' => $fidelitySettings->actif,
                'valeur_fcfa_1_point' => (float) $fidelitySettings->valeur_fcfa_1_point,
            ],
            'payment_method_settings' => [
                'wave_enabled' => $paymentMethods->wave_enabled,
                'orange_money_enabled' => $paymentMethods->orange_money_enabled,
            ],
        ]);
    }

    /**
     * Suppression de compte client (RGPD).
     * Les commandes et montants sont conservés pour les statistiques ; le profil client est anonymisé.
     * Le compte utilisateur est supprimé ; les commandes restent liées au client anonymisé (client_id inchangé).
     */
    public function deleteAccount(Request $request)
    {
        $request->validate([
            'password' => 'required|string',
        ]);

        $user = $request->user();

        $staffRoles = ['admin', 'manager', 'serveur', 'caissier'];
        foreach ($staffRoles as $role) {
            if ($user->hasRole($role)) {
                return response()->json([
                    'message' => 'La suppression de compte n\'est pas disponible pour les comptes personnel.',
                ], 403);
            }
        }

        if (! $user->hasRole('client')) {
            return response()->json([
                'message' => 'Seuls les comptes clients peuvent être supprimés depuis l\'application.',
            ], 403);
        }

        if (! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Mot de passe incorrect.',
                'errors' => ['password' => ['Mot de passe incorrect.']],
            ], 422);
        }

        try {
            DB::transaction(function () use ($user) {
                $user->tokens()->delete();

                $client = $user->client;
                if ($client) {
                    $anonPhone = 'deleted_'.$client->id.'_'.time();
                    $client->update([
                        'user_id' => null,
                        'nom' => 'Compte',
                        'prenom' => 'supprimé',
                        'email' => null,
                        'telephone' => $anonPhone,
                        'points_fidelite' => 0,
                        'actif' => false,
                    ]);
                }

                $user->syncRoles([]);
                $user->delete();
            });

            return response()->json([
                'message' => 'Votre compte a été supprimé. Vos commandes passées restent conservées de façon anonyme pour nos statistiques.',
            ], 200);
        } catch (\Exception $e) {
            Log::error('deleteAccount: '.$e->getMessage(), ['trace' => $e->getTraceAsString()]);

            return response()->json([
                'message' => 'Impossible de supprimer le compte pour le moment. Réessayez plus tard.',
            ], 500);
        }
    }

    /**
     * Rafraîchir le token
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function refresh(Request $request)
    {
        $user = $request->user();
        
        // Supprimer l'ancien token
        $request->user()->currentAccessToken()->delete();
        
        // Créer un nouveau token
        $user->load('roles.permissions');
        $permissions = $user->getAllPermissions()->pluck('name')->toArray();
        $token = $user->createToken('auth_token', $permissions)->plainTextToken;

        return response()->json([
            'message' => 'Token rafraîchi avec succès',
            'token' => $token,
            'token_type' => 'Bearer',
        ]);
    }
}
