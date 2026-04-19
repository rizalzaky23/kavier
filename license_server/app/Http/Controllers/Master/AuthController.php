<?php

namespace App\Http\Controllers\Master;

use App\Http\Controllers\Controller;
use App\Models\MasterAdmin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function showLogin()
    {
        if (session('master_admin_id')) {
            return redirect()->route('master.dashboard');
        }
        return view('master.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        $admin = MasterAdmin::where('email', $request->email)->first();

        if (!$admin || !Hash::check($request->password, $admin->password)) {
            return back()->withErrors(['email' => 'Email atau password salah.'])->withInput();
        }

        session(['master_admin_id' => $admin->id, 'master_admin_name' => $admin->name]);

        return redirect()->route('master.dashboard');
    }

    public function logout()
    {
        session()->forget(['master_admin_id', 'master_admin_name']);
        return redirect()->route('master.login');
    }
}
