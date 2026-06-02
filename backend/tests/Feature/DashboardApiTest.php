<?php

namespace Tests\Feature;

use App\Models\CheckIn;
use App\Models\Event;
use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DashboardApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_summary_returns_counts(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'is_active' => true]);
        $employee = User::factory()->create(['role' => 'employee', 'is_active' => true]);

        Task::create([
            'title' => 'Acil görev',
            'assigned_to' => $employee->id,
            'created_by' => $admin->id,
            'status' => 'pending',
            'priority' => 'high',
            'due_date' => now()->addDays(2)->toDateString(),
        ]);

        CheckIn::create([
            'user_id' => $employee->id,
            'work_date' => now()->toDateString(),
            'status' => 'available',
            'checked_in_at' => now(),
        ]);

        Event::create([
            'title' => 'Bugünkü toplantı',
            'user_id' => $employee->id,
            'starts_at' => now()->addHour(),
            'is_private' => false,
        ]);

        Sanctum::actingAs($admin);

        $this->getJson('/api/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.tasks.total', 1)
            ->assertJsonPath('data.tasks.high_priority', 1)
            ->assertJsonPath('data.tasks.due_soon', 1)
            ->assertJsonPath('data.check_ins.today_count', 1)
            ->assertJsonPath('data.events.today_count', 1);
    }
}
