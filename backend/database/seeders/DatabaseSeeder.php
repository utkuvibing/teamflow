<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@miniteamflow.local'],
            [
                'name' => 'Admin',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'position' => 'Yönetici',
                'is_active' => true,
            ],
        );

        User::updateOrCreate(
            ['email' => 'admin2@miniteamflow.local'],
            [
                'name' => 'Admin 2',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'position' => 'Yönetici',
                'is_active' => true,
            ],
        );

        User::updateOrCreate(
            ['email' => 'employee@miniteamflow.local'],
            [
                'name' => 'Demo Çalışan',
                'password' => Hash::make('password'),
                'role' => 'employee',
                'position' => 'Mobil Geliştirici',
                'is_active' => true,
            ],
        );

        User::updateOrCreate(
            ['email' => 'employee2@miniteamflow.local'],
            [
                'name' => 'Demo Çalışan 2',
                'password' => Hash::make('password'),
                'role' => 'employee',
                'position' => 'Operasyon Uzmanı',
                'is_active' => true,
            ],
        );
    }
}
