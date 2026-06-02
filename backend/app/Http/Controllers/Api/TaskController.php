<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Task;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TaskController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Task::query()->with(['assignee:id,name,email,role,position', 'creator:id,name,email,role,position']);

        if (! $user->isAdmin()) {
            $query->where(function ($query) use ($user): void {
                $query->where('assigned_to', $user->id)
                    ->orWhere('created_by', $user->id);
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('priority')) {
            $query->where('priority', $request->string('priority'));
        }

        $tasks = $query->latest()->get();

        return response()->json([
            'success' => true,
            'message' => 'Görevler listelendi.',
            'data' => ['tasks' => $tasks],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'assigned_to' => ['nullable', 'integer', Rule::exists('users', 'id')->where('is_active', true)],
            'priority' => ['required', Rule::in(Task::PRIORITIES)],
            'due_date' => ['nullable', 'date'],
        ]);

        if (! $user->isAdmin()) {
            $validated['assigned_to'] = $user->id;
        } else {
            $validated['assigned_to'] = $validated['assigned_to'] ?? $user->id;
        }

        $task = Task::create([
            ...$validated,
            'created_by' => $user->id,
            'status' => 'pending',
        ])->load(['assignee:id,name,email,role,position', 'creator:id,name,email,role,position']);

        if ($task->assigned_to !== $user->id) {
            AppNotification::create([
                'user_id' => $task->assigned_to,
                'title' => 'Yeni görev atandı',
                'body' => $task->title,
                'type' => 'task_assigned',
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Görev oluşturuldu.',
            'data' => ['task' => $task],
        ], 201);
    }

    public function show(Request $request, Task $task): JsonResponse
    {
        $this->authorizeTaskAccess($request, $task);

        $task->load([
            'assignee:id,name,email,role,position',
            'creator:id,name,email,role,position',
            'comments.user:id,name,email,role,position',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Görev detayı alındı.',
            'data' => ['task' => $task],
        ]);
    }

    public function update(Request $request, Task $task): JsonResponse
    {
        $this->authorizeTaskAccess($request, $task);

        $user = $request->user();
        $rules = [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'assigned_to' => ['sometimes', 'integer', Rule::exists('users', 'id')->where('is_active', true)],
            'status' => ['sometimes', Rule::in(Task::STATUSES)],
            'priority' => ['sometimes', Rule::in(Task::PRIORITIES)],
            'due_date' => ['sometimes', 'nullable', 'date'],
        ];

        $validated = $request->validate($rules);

        if (! $user->isAdmin()) {
            unset($validated['assigned_to']);

            if ($task->created_by !== $user->id) {
                unset($validated['title'], $validated['description'], $validated['priority'], $validated['due_date']);
            }
        }

        if (($validated['status'] ?? null) === 'completed' && $task->status !== 'completed') {
            $validated['completed_at'] = now();
        }

        if (isset($validated['status']) && $validated['status'] !== 'completed') {
            $validated['completed_at'] = null;
        }

        $task->update($validated);
        $task->load(['assignee:id,name,email,role,position', 'creator:id,name,email,role,position']);

        return response()->json([
            'success' => true,
            'message' => 'Görev güncellendi.',
            'data' => ['task' => $task],
        ]);
    }

    public function destroy(Request $request, Task $task): JsonResponse
    {
        $user = $request->user();

        if (! $user->isAdmin() && $task->created_by !== $user->id) {
            abort(403, 'Bu görevi silme yetkin yok.');
        }

        $task->delete();

        return response()->json([
            'success' => true,
            'message' => 'Görev silindi.',
            'data' => null,
        ]);
    }

    private function authorizeTaskAccess(Request $request, Task $task): void
    {
        $user = $request->user();

        if ($user->isAdmin()) {
            return;
        }

        if ($task->assigned_to === $user->id || $task->created_by === $user->id) {
            return;
        }

        abort(403, 'Bu göreve erişim yetkin yok.');
    }
}
