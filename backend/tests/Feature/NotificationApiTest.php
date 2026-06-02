<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_task_assignment_creates_notification(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'is_active' => true]);
        $employee = User::factory()->create(['role' => 'employee', 'is_active' => true]);
        Sanctum::actingAs($admin);

        $this->postJson('/api/tasks', [
            'title' => 'Bildirimli görev',
            'assigned_to' => $employee->id,
            'priority' => 'medium',
        ])->assertCreated();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $employee->id,
            'type' => 'task_assigned',
            'body' => 'Bildirimli görev',
        ]);
    }

    public function test_user_can_list_and_read_own_notification(): void
    {
        $employee = User::factory()->create(['role' => 'employee', 'is_active' => true]);
        $notification = AppNotification::create([
            'user_id' => $employee->id,
            'title' => 'Test bildirimi',
            'body' => 'Detay',
        ]);
        Sanctum::actingAs($employee);

        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 1);

        $this->patchJson("/api/notifications/{$notification->id}/read")
            ->assertOk()
            ->assertJsonPath('data.notification.read_at', fn ($value) => $value !== null);
    }
}
