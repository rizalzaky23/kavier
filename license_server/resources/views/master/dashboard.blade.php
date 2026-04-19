@extends('master.layout')

@section('title', 'Dashboard — POS Master')
@section('page-title', 'Dashboard')
@section('page-sub', 'Ringkasan status lisensi semua user')

@section('content')

<!-- Stats Grid -->
<div class="stats-grid">
  <div class="stat-card c-primary">
    <div class="stat-icon">👥</div>
    <div class="stat-value">{{ $total }}</div>
    <div class="stat-label">Total User</div>
  </div>
  <div class="stat-card c-success">
    <div class="stat-icon">✅</div>
    <div class="stat-value">{{ $active }}</div>
    <div class="stat-label">Lisensi Aktif</div>
  </div>
  <div class="stat-card c-danger">
    <div class="stat-icon">❌</div>
    <div class="stat-value">{{ $expired }}</div>
    <div class="stat-label">Lisensi Expired</div>
  </div>
  <div class="stat-card c-warning">
    <div class="stat-icon">⚠️</div>
    <div class="stat-value">{{ $expiring }}</div>
    <div class="stat-label">Hampir Expired (7 hari)</div>
  </div>
  <div class="stat-card c-info">
    <div class="stat-icon">🚫</div>
    <div class="stat-value">{{ $disabled }}</div>
    <div class="stat-label">Dinonaktifkan</div>
  </div>
</div>

<!-- Recent Users Table -->
<div class="card">
  <div class="card-header">
    <div class="card-title">User Terbaru</div>
    <a href="{{ route('master.users.create') }}" class="btn btn-primary">
      ＋ Tambah User
    </a>
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Nama / Toko</th>
          <th>Email</th>
          <th>Mulai</th>
          <th>Berakhir</th>
          <th>Status</th>
          <th>Aksi</th>
        </tr>
      </thead>
      <tbody>
        @forelse ($recentUsers as $user)
          <tr>
            <td>
              <div style="font-weight:600">{{ $user->name }}</div>
              <div style="font-size:12px;color:var(--muted)">{{ $user->store_name ?? '-' }}</div>
            </td>
            <td style="color:var(--muted)">{{ $user->email }}</td>
            <td>{{ $user->license_start?->format('d M Y') ?? '-' }}</td>
            <td>
              @if($user->license_end)
                {{ $user->license_end->format('d M Y') }}
                @if($user->isLicenseValid() && $user->daysRemaining() <= 7)
                  <span style="font-size:11px;color:#fbbf24">({{ $user->daysRemaining() }} hari)</span>
                @endif
              @else
                -
              @endif
            </td>
            <td>
              @php $label = $user->statusLabel(); @endphp
              @if(str_contains($label, 'Aktif'))
                <span class="badge badge-success">✅ {{ $label }}</span>
              @elseif(str_contains($label, 'Hampir'))
                <span class="badge badge-warning">⚠️ {{ $label }}</span>
              @elseif(str_contains($label, 'Expired'))
                <span class="badge badge-danger">❌ Expired</span>
              @elseif(str_contains($label, 'Dinonaktifkan'))
                <span class="badge badge-muted">🚫 Nonaktif</span>
              @else
                <span class="badge badge-muted">{{ $label }}</span>
              @endif
            </td>
            <td>
              <a href="{{ route('master.users.edit', $user) }}" class="btn btn-ghost btn-sm">Edit</a>
            </td>
          </tr>
        @empty
          <tr>
            <td colspan="6" style="text-align:center;color:var(--muted);padding:32px">
              Belum ada user. <a href="{{ route('master.users.create') }}" style="color:var(--primary)">Tambah sekarang</a>
            </td>
          </tr>
        @endforelse
      </tbody>
    </table>
  </div>

  @if($recentUsers->count() > 0)
    <div style="margin-top:16px;text-align:center">
      <a href="{{ route('master.users.index') }}" style="color:var(--primary);font-size:13px;text-decoration:none">
        Lihat semua user →
      </a>
    </div>
  @endif
</div>

@endsection
