<?php

use App\Http\Controllers\Master\AuthController;
use App\Http\Controllers\Master\UserController;
use App\Http\Middleware\MasterAuth;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes — Master Panel
|--------------------------------------------------------------------------
*/

// ── Auth ─────────────────────────────────────────────────────────────────
Route::prefix('master')->name('master.')->group(function () {

    // Login (public)
    Route::get('login',  [AuthController::class, 'showLogin'])->name('login');
    Route::post('login', [AuthController::class, 'login'])->name('login.post');

    // Protected routes
    Route::middleware(MasterAuth::class)->group(function () {
        Route::get('logout',    [AuthController::class, 'logout'])->name('logout');
        Route::get('dashboard', [UserController::class, 'dashboard'])->name('dashboard');

        // Users CRUD
        Route::prefix('users')->name('users.')->group(function () {
            Route::get('/',                 [UserController::class, 'index'])->name('index');
            Route::get('create',            [UserController::class, 'create'])->name('create');
            Route::post('/',                [UserController::class, 'store'])->name('store');
            Route::get('{user}/edit',       [UserController::class, 'edit'])->name('edit');
            Route::put('{user}',            [UserController::class, 'update'])->name('update');
            Route::delete('{user}',         [UserController::class, 'destroy'])->name('destroy');
            Route::post('{user}/extend',    [UserController::class, 'extendLicense'])->name('extend');
        });
    });
});

// Redirect root ke master
Route::get('/', function () {
    return redirect()->route('master.login');
});
