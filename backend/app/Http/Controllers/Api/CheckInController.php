<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CheckIn;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CheckInController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $date = $request->input('date', now()->toDateString());

        $query = CheckIn::query()
            ->with('user:id,name,email,role,position')
            ->whereDate('work_date', $date)
            ->latest('checked_in_at');

        if (! $user->isAdmin()) {
            $query->where('user_id', $user->id);
        }

        $checkIns = $query->get();
        $missingUsers = [];

        if ($user->isAdmin()) {
            $checkedUserIds = $checkIns->pluck('user_id')->all();
            $missingUsers = User::query()
                ->select('id', 'name', 'email', 'role', 'position')
                ->where('is_active', true)
                ->whereNotIn('id', $checkedUserIds)
                ->orderBy('name')
                ->get();
        }

        return response()->json([
            'success' => true,
            'message' => 'Check-in kayıtları listelendi.',
            'data' => [
                'date' => $date,
                'check_ins' => $checkIns,
                'missing_users' => $missingUsers,
            ],
        ]);
    }

    public function storeToday(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['required', Rule::in(CheckIn::STATUSES)],
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        $user = $request->user();
        $today = now()->toDateString();

        $checkIn = CheckIn::updateOrCreate(
            ['user_id' => $user->id, 'work_date' => $today],
            [
                'status' => $validated['status'],
                'note' => $validated['note'] ?? null,
                'checked_in_at' => now(),
            ]
        )->load('user:id,name,email,role,position');

        return response()->json([
            'success' => true,
            'message' => 'Bugünkü check-in kaydedildi.',
            'data' => ['check_in' => $checkIn],
        ], 201);
    }
}
