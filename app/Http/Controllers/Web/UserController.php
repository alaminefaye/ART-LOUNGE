<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Spatie\Permission\Models\Role;

class UserController extends Controller
{
    public function index()
    {
        $users = User::with('roles')->paginate(10);
        return view('users.index', compact('users'));
    }

    public function create()
    {
        $roles = Role::all();
        return view('users.create', compact('roles'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'roles'    => 'required|array|min:1',
            'roles.*'  => 'exists:roles,name',
            'pin'      => 'nullable|string|size:4|regex:/^[0-9]{4}$/',
        ]);

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
            'pin'      => !empty($validated['pin']) ? Hash::make($validated['pin']) : null,
        ]);

        $user->syncRoles($validated['roles']);

        return redirect()->route('users.index')
                        ->with('success', 'Utilisateur créé avec succès !' . (!empty($validated['pin']) ? ' PIN : ' . $validated['pin'] : ' (aucun PIN défini)'));
    }

    public function show(User $user)
    {
        $user->load('roles.permissions');
        return view('users.show', compact('user'));
    }

    public function edit(User $user)
    {
        $roles = Role::all();
        return view('users.edit', compact('user', 'roles'));
    }

    public function update(Request $request, User $user)
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => ['required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'password' => 'nullable|string|min:8|confirmed',
            'roles'    => 'required|array|min:1',
            'roles.*'  => 'exists:roles,name',
            'pin'      => 'nullable|string|size:4|regex:/^[0-9]{4}$/',
        ]);

        $user->update([
            'name'  => $validated['name'],
            'email' => $validated['email'],
        ]);

        if (!empty($validated['password'])) {
            $user->update(['password' => Hash::make($validated['password'])]);
        }

        if (!empty($validated['pin'])) {
            $user->update(['pin' => Hash::make($validated['pin'])]);
        }

        $user->syncRoles($validated['roles']);

        $pinMsg = !empty($validated['pin']) ? ' PIN mis à jour : ' . $validated['pin'] : '';
        return redirect()->route('users.index')
                        ->with('success', 'Utilisateur modifié avec succès !' . $pinMsg);
    }

    public function destroy(User $user)
    {
        // Empêcher la suppression de son propre compte
        if ($user->id === auth()->id()) {
            return back()->with('error', 'Vous ne pouvez pas supprimer votre propre compte.');
        }

        // Empêcher la suppression du dernier admin
        if ($user->hasRole('admin')) {
            $adminCount = User::role('admin')->count();
            if ($adminCount <= 1) {
                return back()->with('error', 'Impossible de supprimer le dernier administrateur.');
            }
        }

        $user->delete();

        return redirect()->route('users.index')
                        ->with('success', 'Utilisateur supprimé avec succès !');
    }
}

