<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RoleController extends Controller
{
    public function index()
    {
        $roles = Role::withCount('permissions', 'users')
            ->orderBy('name')
            ->paginate(10);
        return view('roles.index', compact('roles'));
    }

    public function create()
    {
        $permissions = Permission::all()->groupBy('group');
        return view('roles.create', compact('permissions'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:roles,name',
            'permissions' => 'nullable|array',
            'permissions.*' => 'exists:permissions,name',
        ]);

        $role = Role::create(['name' => $validated['name']]);

        if (isset($validated['permissions'])) {
            $role->syncPermissions($validated['permissions']);
        }

        return redirect()->route('roles.index')
                        ->with('success', 'Rôle créé avec succès !');
    }

    public function show(Role $role)
    {
        $role->load('permissions', 'users');
        $permissionsByGroup = $role->permissions->groupBy(function($permission) {
            return $permission->group ?? 'other';
        });
        return view('roles.show', compact('role', 'permissionsByGroup'));
    }

    public function edit(Role $role)
    {
        $permissions = Permission::all()->groupBy('group');
        $rolePermissions = $role->permissions->pluck('name')->toArray();
        return view('roles.edit', compact('role', 'permissions', 'rolePermissions'));
    }

    public function update(Request $request, Role $role)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255', Rule::unique('roles')->ignore($role->id)],
            'permissions' => 'nullable|array',
            'permissions.*' => 'exists:permissions,name',
        ]);

        $role->update(['name' => $validated['name']]);
        
        $role->syncPermissions($validated['permissions'] ?? []);

        return redirect()->route('roles.index')
                        ->with('success', 'Rôle modifié avec succès !');
    }

    public function destroy(Role $role)
    {
        // Empêcher la suppression du rôle admin
        if ($role->name === 'admin') {
            return back()->with('error', 'Le rôle administrateur ne peut pas être supprimé.');
        }

        // Vérifier si le rôle est assigné à des utilisateurs
        if ($role->users()->count() > 0) {
            return back()->with('error', 'Ce rôle est assigné à des utilisateurs et ne peut pas être supprimé.');
        }

        $role->delete();

        return redirect()->route('roles.index')
                        ->with('success', 'Rôle supprimé avec succès !');
    }
}

