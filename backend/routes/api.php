<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\TransactionController;
use App\Http\Middleware\AdminOnly;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — POS App
|--------------------------------------------------------------------------
*/

// ── Public ──────────────────────────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('login', [AuthController::class, 'login']);
});

// ── Authenticated ────────────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::prefix('auth')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('me',     [AuthController::class, 'me']);
    });

    // Categories
    Route::apiResource('categories', CategoryController::class)->except('show');

    // Products
    Route::get('products/low-stock', [ProductController::class, 'lowStock']);
    Route::apiResource('products', ProductController::class);

    // Transactions
    Route::get('transactions',            [TransactionController::class, 'index']);
    Route::get('transactions/{transaction}', [TransactionController::class, 'show']);
    Route::post('transactions',           [TransactionController::class, 'store']);
    Route::patch('transactions/{transaction}/cancel', [TransactionController::class, 'cancel']);

    // Reports
    Route::prefix('reports')->group(function () {
        Route::get('summary',      [ReportController::class, 'summary']);
        Route::get('top-products', [ReportController::class, 'topProducts']);
        Route::get('daily-chart',  [ReportController::class, 'dailyChart']);
        Route::get('export',       [ReportController::class, 'export']);
    });

    // ── Admin Only ───────────────────────────────────────────────────────
    Route::middleware(AdminOnly::class)->group(function () {
        Route::get('users',  [AuthController::class, 'users']);
        Route::post('users', [AuthController::class, 'storeUser']);
    });
});
