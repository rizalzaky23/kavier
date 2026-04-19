<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LicenseUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class LicenseController extends Controller
{
    /**
     * POST /api/license/verify
     * Dipanggil oleh Flutter saat login.
     * Body: { "email": "...", "password": "..." }
     */
    public function verify(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = LicenseUser::where('email', $request->email)->first();

        // User tidak ditemukan
        if (!$user) {
            return response()->json([
                'valid'   => false,
                'code'    => 'USER_NOT_FOUND',
                'message' => 'Akun tidak terdaftar di sistem lisensi.',
            ], 404);
        }

        // Password salah
        if (!Hash::check($request->password, $user->password)) {
            return response()->json([
                'valid'   => false,
                'code'    => 'INVALID_CREDENTIALS',
                'message' => 'Email atau password tidak sesuai.',
            ], 401);
        }

        // Akun dinonaktifkan
        if (!$user->is_active) {
            return response()->json([
                'valid'       => false,
                'code'        => 'ACCOUNT_DISABLED',
                'message'     => 'Akun Anda telah dinonaktifkan. Hubungi administrator.',
                'license_end' => null,
            ], 403);
        }

        // Tidak ada lisensi
        if (!$user->license_end) {
            return response()->json([
                'valid'       => false,
                'code'        => 'NO_LICENSE',
                'message'     => 'Belum ada lisensi yang ditetapkan. Hubungi administrator.',
                'license_end' => null,
            ], 403);
        }

        // Lisensi expired
        if (!$user->isLicenseValid()) {
            // Update last_verified_at tetap
            $user->update(['last_verified_at' => now()]);

            return response()->json([
                'valid'       => false,
                'code'        => 'LICENSE_EXPIRED',
                'message'     => 'Masa lisensi Anda telah berakhir. Silakan perpanjang.',
                'license_end' => $user->license_end->toDateString(),
                'store_name'  => $user->store_name,
            ], 403);
        }

        // Lisensi VALID ✓
        $user->update(['last_verified_at' => now()]);

        return response()->json([
            'valid'          => true,
            'code'           => 'LICENSE_VALID',
            'message'        => 'Lisensi valid.',
            'name'           => $user->name,
            'store_name'     => $user->store_name,
            'email'          => $user->email,
            'license_start'  => $user->license_start?->toDateString(),
            'license_end'    => $user->license_end->toDateString(),
            'days_remaining' => $user->daysRemaining(),
        ]);
    }

    /**
     * POST /api/license/check
     * Re-check ringan (hanya berdasarkan email, tanpa password).
     * Dipakai untuk periodic background check.
     * Body: { "email": "..." }
     */
    public function check(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = LicenseUser::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['valid' => false, 'code' => 'USER_NOT_FOUND'], 404);
        }

        if (!$user->is_active) {
            return response()->json(['valid' => false, 'code' => 'ACCOUNT_DISABLED'], 403);
        }

        if (!$user->license_end || !$user->isLicenseValid()) {
            return response()->json([
                'valid'       => false,
                'code'        => 'LICENSE_EXPIRED',
                'license_end' => $user->license_end?->toDateString(),
            ], 403);
        }

        return response()->json([
            'valid'          => true,
            'code'           => 'LICENSE_VALID',
            'license_end'    => $user->license_end->toDateString(),
            'days_remaining' => $user->daysRemaining(),
        ]);
    }
}
