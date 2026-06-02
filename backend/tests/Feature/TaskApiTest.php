<?php

namespace Tests\Feature;

use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TaskApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_and_list_tasks(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'is_active' => true]);
        $employee = User::factory()->create(['role' => 'employee', 'is_active' => true]);
        Sanctum::actingAs($admin);

        $this->postJson('/api/tasks', [
            'title' => 'API görev testi',
            'description' => 'Deneme açıklaması',
            'assigned_to' => $employee->id,
            'priority' => 'high',
        ])->assertCreated()
            ->assertJsonPath('data.task.title', 'API görev testi')
            ->assertJsonPath('data.task.assigned_to', $employee->id);

        $this->getJson('/api/tasks')
            ->assertOk()
            ->assertJsonCount(1, 'data.tasks');
    }

    public function test_employee_can_update_own_task_status(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'is_active' => true]);
        $employee = User::factory()->create(['role' => 'employee', 'is_active' => true]);
        $task = Task::create([
            'title' => 'Durum değişecek',
            'assigned_to' => $employee->id,
            'created_by' => $admin->id,
            'status' => 'pending',
            'priority' => 'medium',
        ]);
        Sanctum::actingAs($employee);

        $this->patchJson("/api/tasks/{$task->id}", ['status' => 'completed'])
            ->assertOk()
            ->assertJsonPath('data.task.status', 'completed');

        $this->assertNotNull($task->fresh()->completed_at);
    }
}
