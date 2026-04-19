<?php

use App\Http\Controllers\Api\LicenseController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — License Server
|--------------------------------------------------------------------------
| Dipanggil oleh Flutter POS App
*/

Route::prefix('license')->group(function () {
    // Verifikasi lisensi saat login (butuh email + password)
    Route::post('verify', [LicenseController::class, 'verify']);

    // Re-check ringan (hanya email, untuk periodic check)
    Route::post('check', [LicenseController::class, 'check']);
});
