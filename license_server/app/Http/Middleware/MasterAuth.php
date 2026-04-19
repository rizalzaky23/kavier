<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class MasterAuth
{
    public function handle(Request $request, Closure $next)
    {
        if (!session('master_admin_id')) {
            return redirect()->route('master.login')
                             ->with('error', 'Anda harus login terlebih dahulu.');
        }
        return $next($request);
    }
}
