<?php

namespace Tests\Feature;

use App\Models\CheckIn;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CheckInApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_employee_can_create_today_check_in(): void
    {
        $employee = User::factory()->create(['role' => 'employee', 'is_active' => true]);
        Sanctum::actingAs($employee);

        $this->postJson('/api/check-ins/today', [
            'status' => 'available',
            'note' => 'Ofisteyim.',
        ])->assertCreated()
            ->assertJsonPath('data.check_in.user_id', $employee->id)
            ->assertJsonPath('data.check_in.status', 'available');

        $this->assertDatabaseHas('check_ins', [
            'user_id' => $employee->id,
            'work_date' => now()->toDateString(),
        ]);
    }

    public function test_admin_can_see_missing_users_for_today(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'is_active' => true]);
        $checked = User::factory()->create(['role' => 'employee', 'is_active' => true]);
        $missing = User::factory()->create(['role' => 'employee', 'is_active' => true]);

        CheckIn::create([
            'user_id' => $checked->id,
            'work_date' => now()->toDateString(),
            'status' => 'remote',
            'checked_in_at' => now(),
        ]);

        Sanctum::actingAs($admin);

        $this->getJson('/api/check-ins')
            ->assertOk()
            ->assertJsonCount(1, 'data.check_ins')
            ->assertJsonFragment(['id' => $missing->id, 'name' => $missing->name]);
    }
}
