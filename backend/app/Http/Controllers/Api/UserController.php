<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        if (! $request->user()->isAdmin()) {
            abort(403, 'Bu işlem için admin yetkisi gerekir.');
        }

        $users = User::query()
            ->select(['id', 'name', 'email', 'role', 'position', 'is_active', 'created_at'])
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Kullanıcılar listelendi.',
            'data' => ['users' => $users],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        if (! $request->user()->isAdmin()) {
            abort(403, 'Bu işlem için admin yetkisi gerekir.');
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'role' => ['required', Rule::in(['admin', 'employee'])],
            'position' => ['nullable', 'string', 'max:255'],
        ]);

        $user = User::create([
            ...$validated,
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Kullanıcı oluşturuldu.',
            'data' => ['user' => $user],
        ], 201);
    }
}
