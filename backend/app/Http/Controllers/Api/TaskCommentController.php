<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaskCommentController extends Controller
{
    public function store(Request $request, Task $task): JsonResponse
    {
        $user = $request->user();

        if (! $user->isAdmin() && $task->assigned_to !== $user->id && $task->created_by !== $user->id) {
            abort(403, 'Bu göreve yorum yazma yetkin yok.');
        }

        $validated = $request->validate([
            'comment' => ['required', 'string', 'max:2000'],
        ]);

        $comment = $task->comments()->create([
            'user_id' => $user->id,
            'comment' => $validated['comment'],
        ])->load('user:id,name,email,role,position');

        return response()->json([
            'success' => true,
            'message' => 'Yorum eklendi.',
            'data' => ['comment' => $comment],
        ], 201);
    }
}
