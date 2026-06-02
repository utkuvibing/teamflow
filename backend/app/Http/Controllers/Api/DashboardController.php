<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CheckIn;
use App\Models\Event;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $taskQuery = Task::query();
        $eventQuery = Event::query();
        $checkInQuery = CheckIn::query()->whereDate('work_date', now()->toDateString());

        if (! $user->isAdmin()) {
            $taskQuery->where(function ($query) use ($user): void {
                $query->where('assigned_to', $user->id)->orWhere('created_by', $user->id);
            });
            $eventQuery->where(function ($query) use ($user): void {
                $query->where('user_id', $user->id)->orWhere('is_private', false);
            });
            $checkInQuery->where('user_id', $user->id);
        }

        $tasksByStatus = (clone $taskQuery)
            ->selectRaw('status, count(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        $tasksByPriority = (clone $taskQuery)
            ->selectRaw('priority, count(*) as total')
            ->groupBy('priority')
            ->pluck('total', 'priority');

        $dueSoonCount = (clone $taskQuery)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereNotNull('due_date')
            ->whereDate('due_date', '<=', now()->addDays(7)->toDateString())
            ->count();

        $todayEventCount = (clone $eventQuery)
            ->whereDate('starts_at', now()->toDateString())
            ->count();

        return response()->json([
            'success' => true,
            'message' => 'Dashboard özeti alındı.',
            'data' => [
                'tasks' => [
                    'total' => (clone $taskQuery)->count(),
                    'pending' => (int) ($tasksByStatus['pending'] ?? 0),
                    'in_progress' => (int) ($tasksByStatus['in_progress'] ?? 0),
                    'completed' => (int) ($tasksByStatus['completed'] ?? 0),
                    'cancelled' => (int) ($tasksByStatus['cancelled'] ?? 0),
                    'high_priority' => (int) ($tasksByPriority['high'] ?? 0),
                    'due_soon' => $dueSoonCount,
                ],
                'check_ins' => [
                    'today_count' => (clone $checkInQuery)->count(),
                ],
                'events' => [
                    'today_count' => $todayEventCount,
                    'upcoming_count' => (clone $eventQuery)->where('starts_at', '>=', now())->count(),
                ],
            ],
        ]);
    }
}
