<?php

namespace Database\Seeders;

use App\Models\LicenseUser;
use App\Models\MasterAdmin;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Super Admin default
        MasterAdmin::firstOrCreate(
            ['email' => 'superadmin@josephscrd.my.id'],
            [
                'name'     => 'Super Admin',
                'password' => Hash::make('superadmin123'),
            ]
        );

        // Contoh user lisensi untuk testing
        LicenseUser::firstOrCreate(
            ['email' => 'demo@toko.com'],
            [
                'name'          => 'Demo Toko',
                'password'      => Hash::make('demo1234'),
                'store_name'    => 'Toko Demo',
                'license_start' => now()->toDateString(),
                'license_end'   => now()->addDays(30)->toDateString(),
                'is_active'     => true,
                'notes'         => 'Akun demo untuk testing.',
            ]
        );
    }
}
