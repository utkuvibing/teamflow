<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EventApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_employee_can_create_event(): void
    {
        $employee = User::factory()->create(['role' => 'employee', 'is_active' => true]);
        Sanctum::actingAs($employee);

        $this->postJson('/api/events', [
            'title' => 'Planlama toplantısı',
            'starts_at' => now()->addDay()->toISOString(),
            'ends_at' => now()->addDay()->addHour()->toISOString(),
            'is_private' => false,
        ])->assertCreated()
            ->assertJsonPath('data.event.title', 'Planlama toplantısı')
            ->assertJsonPath('data.event.user_id', $employee->id);
    }

    public function test_employee_cannot_see_other_private_event(): void
    {
        $owner = User::factory()->create(['role' => 'employee', 'is_active' => true]);
        $viewer = User::factory()->create(['role' => 'employee', 'is_active' => true]);

        Event::create([
            'title' => 'Özel not',
            'user_id' => $owner->id,
            'starts_at' => now()->addDay(),
            'is_private' => true,
        ]);

        Sanctum::actingAs($viewer);

        $this->getJson('/api/events')
            ->assertOk()
            ->assertJsonCount(0, 'data.events');
    }

    public function test_admin_can_see_private_events(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'is_active' => true]);
        $owner = User::factory()->create(['role' => 'employee', 'is_active' => true]);

        Event::create([
            'title' => 'Özel etkinlik',
            'user_id' => $owner->id,
            'starts_at' => now()->addDay(),
            'is_private' => true,
        ]);

        Sanctum::actingAs($admin);

        $this->getJson('/api/events')
            ->assertOk()
            ->assertJsonCount(1, 'data.events');
    }
}
