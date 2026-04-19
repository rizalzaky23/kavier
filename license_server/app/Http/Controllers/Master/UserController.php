<?php

namespace App\Http\Controllers\Master;

use App\Http\Controllers\Controller;
use App\Models\LicenseUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function dashboard()
    {
        $total    = LicenseUser::count();
        $active   = LicenseUser::where('is_active', true)
                        ->whereDate('license_end', '>=', now())
                        ->count();
        $expired  = LicenseUser::where('is_active', true)
                        ->whereNotNull('license_end')
                        ->whereDate('license_end', '<', now())
                        ->count();
        $expiring = LicenseUser::where('is_active', true)
                        ->whereDate('license_end', '>=', now())
                        ->whereDate('license_end', '<=', now()->addDays(7))
                        ->count();
        $disabled = LicenseUser::where('is_active', false)->count();

        $recentUsers = LicenseUser::latest()->take(5)->get();

        return view('master.dashboard', compact(
            'total', 'active', 'expired', 'expiring', 'disabled', 'recentUsers'
        ));
    }

    public function index(Request $request)
    {
        $query  = LicenseUser::query();
        $search = $request->input('search');
        $status = $request->input('status');

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%$search%")
                  ->orWhere('email', 'like', "%$search%")
                  ->orWhere('store_name', 'like', "%$search%");
            });
        }

        if ($status === 'active') {
            $query->where('is_active', true)->whereDate('license_end', '>=', now());
        } elseif ($status === 'expired') {
            $query->where('is_active', true)->whereDate('license_end', '<', now());
        } elseif ($status === 'disabled') {
            $query->where('is_active', false);
        }

        $users = $query->latest()->paginate(15)->withQueryString();

        return view('master.users.index', compact('users', 'search', 'status'));
    }

    public function create()
    {
        return view('master.users.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name'          => 'required|string|max:255',
            'email'         => 'required|email|unique:license_users,email',
            'password'      => 'required|string|min:6|confirmed',
            'store_name'    => 'nullable|string|max:255',
            'license_start' => 'nullable|date',
            'license_end'   => 'nullable|date|after_or_equal:license_start',
            'is_active'     => 'boolean',
            'notes'         => 'nullable|string|max:500',
        ]);

        LicenseUser::create([
            'name'          => $request->name,
            'email'         => $request->email,
            'password'      => Hash::make($request->password),
            'store_name'    => $request->store_name,
            'license_start' => $request->license_start,
            'license_end'   => $request->license_end,
            'is_active'     => $request->boolean('is_active', true),
            'notes'         => $request->notes,
        ]);

        return redirect()->route('master.users.index')
                         ->with('success', 'User berhasil ditambahkan!');
    }

    public function edit(LicenseUser $user)
    {
        return view('master.users.edit', compact('user'));
    }

    public function update(Request $request, LicenseUser $user)
    {
        $request->validate([
            'name'          => 'required|string|max:255',
            'email'         => 'required|email|unique:license_users,email,' . $user->id,
            'store_name'    => 'nullable|string|max:255',
            'license_start' => 'nullable|date',
            'license_end'   => 'nullable|date',
            'is_active'     => 'boolean',
            'notes'         => 'nullable|string|max:500',
        ]);

        $data = [
            'name'          => $request->name,
            'email'         => $request->email,
            'store_name'    => $request->store_name,
            'license_start' => $request->license_start ?: null,
            'license_end'   => $request->license_end ?: null,
            'is_active'     => $request->boolean('is_active'),
            'notes'         => $request->notes,
        ];

        if ($request->filled('password')) {
            $request->validate(['password' => 'min:6|confirmed']);
            $data['password'] = Hash::make($request->password);
        }

        $user->update($data);

        return redirect()->route('master.users.index')
                         ->with('success', 'User berhasil diperbarui!');
    }

    public function destroy(LicenseUser $user)
    {
        $user->delete();
        return redirect()->route('master.users.index')
                         ->with('success', 'User berhasil dihapus!');
    }

    /**
     * Quick action: extend license by N days from today.
     */
    public function extendLicense(Request $request, LicenseUser $user)
    {
        $request->validate(['days' => 'required|integer|min:1|max:3650']);

        $start = now()->toDateString();
        // Jika masih aktif, extend dari tanggal akhir yang ada
        if ($user->license_end && $user->license_end->isFuture()) {
            $end = $user->license_end->addDays($request->days)->toDateString();
        } else {
            $end = now()->addDays($request->days)->toDateString();
        }

        $user->update([
            'license_start' => $start,
            'license_end'   => $end,
            'is_active'     => true,
        ]);

        return response()->json([
            'success'    => true,
            'message'    => "Lisensi diperpanjang hingga $end",
            'license_end' => $end,
        ]);
    }
}
