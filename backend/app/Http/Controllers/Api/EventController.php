<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EventController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Event::query()->with('user:id,name,email,role,position');

        if (! $user->isAdmin()) {
            $query->where(function ($query) use ($user): void {
                $query->where('user_id', $user->id)->orWhere('is_private', false);
            });
        }

        if ($request->filled('from')) {
            $query->where('starts_at', '>=', $request->date('from'));
        }

        if ($request->filled('to')) {
            $query->where('starts_at', '<=', $request->date('to'));
        }

        return response()->json([
            'success' => true,
            'message' => 'Etkinlikler listelendi.',
            'data' => ['events' => $query->orderBy('starts_at')->get()],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'starts_at' => ['required', 'date'],
            'ends_at' => ['nullable', 'date', 'after_or_equal:starts_at'],
            'is_private' => ['sometimes', 'boolean'],
        ]);

        $event = Event::create([
            ...$validated,
            'user_id' => $request->user()->id,
            'is_private' => $validated['is_private'] ?? false,
        ])->load('user:id,name,email,role,position');

        return response()->json([
            'success' => true,
            'message' => 'Etkinlik oluşturuldu.',
            'data' => ['event' => $event],
        ], 201);
    }

    public function update(Request $request, Event $event): JsonResponse
    {
        $this->authorizeEvent($request, $event);

        $validated = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'starts_at' => ['sometimes', 'required', 'date'],
            'ends_at' => ['sometimes', 'nullable', 'date', 'after_or_equal:starts_at'],
            'is_private' => ['sometimes', 'boolean'],
        ]);

        $event->update($validated);
        $event->load('user:id,name,email,role,position');

        return response()->json([
            'success' => true,
            'message' => 'Etkinlik güncellendi.',
            'data' => ['event' => $event],
        ]);
    }

    public function destroy(Request $request, Event $event): JsonResponse
    {
        $this->authorizeEvent($request, $event);
        $event->delete();

        return response()->json([
            'success' => true,
            'message' => 'Etkinlik silindi.',
            'data' => null,
        ]);
    }

    private function authorizeEvent(Request $request, Event $event): void
    {
        $user = $request->user();

        if ($user->isAdmin() || $event->user_id === $user->id) {
            return;
        }

        abort(403, 'Bu etkinliği düzenleme yetkin yok.');
    }
}
