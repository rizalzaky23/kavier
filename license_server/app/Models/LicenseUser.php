<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class LicenseUser extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'email',
        'password',
        'store_name',
        'license_start',
        'license_end',
        'is_active',
        'notes',
        'last_verified_at',
    ];

    protected $hidden = ['password'];

    protected $casts = [
        'license_start'    => 'date',
        'license_end'      => 'date',
        'is_active'        => 'boolean',
        'last_verified_at' => 'datetime',
    ];

    /**
     * Cek apakah lisensi masih berlaku.
     */
    public function isLicenseValid(): bool
    {
        if (!$this->is_active) return false;
        if ($this->license_end === null) return false;

        return now()->toDateString() <= $this->license_end->toDateString();
    }

    /**
     * Jumlah hari tersisa.
     */
    public function daysRemaining(): int
    {
        if (!$this->license_end) return 0;
        $diff = now()->startOfDay()->diffInDays($this->license_end->startOfDay(), false);
        return max(0, (int) $diff);
    }

    /**
     * Status label.
     */
    public function statusLabel(): string
    {
        if (!$this->is_active) return 'Dinonaktifkan';
        if (!$this->license_end) return 'Tidak Ada Lisensi';
        if ($this->isLicenseValid()) {
            $days = $this->daysRemaining();
            if ($days <= 7) return "Hampir Expired ($days hari)";
            return 'Aktif';
        }
        return 'Expired';
    }
}
