@extends('master.layout')

@section('title', 'Kelola User — POS Master')
@section('page-title', 'Kelola User')
@section('page-sub', 'Daftar semua user POS beserta status lisensi')

@section('content')

<!-- Toolbar -->
<div class="toolbar">
  <form method="GET" action="{{ route('master.users.index') }}" style="display:contents">
    <div class="toolbar-search">
      <input class="search-input" type="text" name="search"
             value="{{ $search }}" placeholder="Cari nama, email, toko...">
      <button class="search-btn" type="submit">🔍</button>
    </div>

    <select name="status" class="filter-select" onchange="this.form.submit()">
      <option value="">Semua Status</option>
      <option value="active"   {{ $status==='active'   ? 'selected' : '' }}>✅ Aktif</option>
      <option value="expired"  {{ $status==='expired'  ? 'selected' : '' }}>❌ Expired</option>
      <option value="disabled" {{ $status==='disabled' ? 'selected' : '' }}>🚫 Nonaktif</option>
    </select>
  </form>

  <a href="{{ route('master.users.create') }}" class="btn btn-primary">＋ Tambah User</a>
</div>

<!-- Table Card -->
<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>User / Toko</th>
          <th>Email</th>
          <th>Mulai</th>
          <th>Berakhir</th>
          <th>Sisa</th>
          <th>Status</th>
          <th>Terakhir Login</th>
          <th>Aksi</th>
        </tr>
      </thead>
      <tbody>
        @forelse ($users as $i => $user)
          <tr id="row-{{ $user->id }}">
            <td style="color:var(--muted)">{{ $users->firstItem() + $i }}</td>
            <td>
              <div style="font-weight:600">{{ $user->name }}</div>
              @if($user->store_name)
                <div style="font-size:12px;color:var(--muted)">🏪 {{ $user->store_name }}</div>
              @endif
            </td>
            <td style="color:var(--muted);font-size:13px">{{ $user->email }}</td>
            <td style="font-size:13px">{{ $user->license_start?->format('d M Y') ?? '-' }}</td>
            <td style="font-size:13px">{{ $user->license_end?->format('d M Y') ?? '-' }}</td>
            <td>
              @if($user->license_end && $user->is_active)
                @php $days = $user->daysRemaining(); @endphp
                <span style="font-size:13px;color:{{ $days <= 7 ? '#fbbf24' : ($days == 0 ? '#f87171' : 'var(--muted)') }}">
                  {{ $days > 0 ? $days.' hari' : 'Habis' }}
                </span>
              @else
                <span style="color:var(--muted)">-</span>
              @endif
            </td>
            <td>
              @php $label = $user->statusLabel(); @endphp
              @if(str_contains($label, 'Aktif') && !str_contains($label, 'Hampir'))
                <span class="badge badge-success">✅ Aktif</span>
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
            <td style="font-size:12px;color:var(--muted)">
              {{ $user->last_verified_at?->setTimezone('Asia/Jakarta')->format('d M H:i') ?? 'Belum pernah' }}
            </td>
            <td>
              <div style="display:flex;gap:6px;flex-wrap:wrap">
                <!-- Quick extend -->
                <button class="btn btn-success btn-sm"
                        onclick="openExtendModal({{ $user->id }}, '{{ addslashes($user->name) }}', {{ $user->daysRemaining() }})">
                  ⏱ Perpanjang
                </button>
                <a href="{{ route('master.users.edit', $user) }}" class="btn btn-ghost btn-sm">✏️</a>
                <form method="POST" action="{{ route('master.users.destroy', $user) }}"
                      onsubmit="return confirm('Hapus user {{ addslashes($user->name) }}? Tindakan ini tidak bisa dibatalkan.')">
                  @csrf @method('DELETE')
                  <button type="submit" class="btn btn-danger btn-sm">🗑</button>
                </form>
              </div>
            </td>
          </tr>
        @empty
          <tr>
            <td colspan="9" style="text-align:center;color:var(--muted);padding:48px">
              @if($search || $status)
                Tidak ada user yang cocok dengan filter. <a href="{{ route('master.users.index') }}" style="color:var(--primary)">Reset filter</a>
              @else
                Belum ada user. <a href="{{ route('master.users.create') }}" style="color:var(--primary)">Tambah sekarang</a>
              @endif
            </td>
          </tr>
        @endforelse
      </tbody>
    </table>
  </div>

  <!-- Pagination -->
  @if($users->hasPages())
    <div class="pagination">
      {{ $users->links('vendor.pagination.simple-bootstrap-4') }}
    </div>
  @endif
</div>

<!-- Extend Modal -->
<div class="modal-overlay" id="extendModal">
  <div class="modal">
    <div class="modal-title">⏱ Perpanjang Lisensi</div>
    <div class="modal-sub" id="extendModalSub">Perpanjang lisensi untuk user.</div>

    <div class="form-group">
      <label class="form-label">Tambah hari</label>
      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px">
        @foreach([7, 14, 30, 60, 90, 180, 365] as $d)
          <button class="btn btn-ghost btn-sm" onclick="setDays({{ $d }})">+{{ $d }}h</button>
        @endforeach
      </div>
      <input type="number" id="extendDays" class="form-control"
             min="1" max="3650" value="30" placeholder="Jumlah hari...">
    </div>

    <div class="modal-actions">
      <button class="btn btn-ghost" onclick="closeExtendModal()">Batal</button>
      <button class="btn btn-primary" onclick="submitExtend()">Perpanjang →</button>
    </div>
  </div>
</div>

@endsection

@push('scripts')
<script>
  let extendUserId = null;

  function openExtendModal(id, name, daysLeft) {
    extendUserId = id;
    document.getElementById('extendModalSub').textContent =
      `Perpanjang lisensi untuk ${name}. Sisa saat ini: ${daysLeft} hari.`;
    document.getElementById('extendModal').classList.add('open');
  }

  function closeExtendModal() {
    extendUserId = null;
    document.getElementById('extendModal').classList.remove('open');
  }

  function setDays(d) {
    document.getElementById('extendDays').value = d;
  }

  async function submitExtend() {
    const days = parseInt(document.getElementById('extendDays').value);
    if (!days || days < 1) { alert('Masukkan jumlah hari yang valid.'); return; }

    const btn = event.target;
    btn.textContent = 'Memproses...';
    btn.disabled = true;

    try {
      const res = await fetch(`/master/users/${extendUserId}/extend`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content
                       || '{{ csrf_token() }}',
        },
        body: JSON.stringify({ days }),
      });
      const data = await res.json();
      if (data.success) {
        closeExtendModal();
        // Show inline toast and reload
        alert('✅ ' + data.message);
        location.reload();
      } else {
        alert('Terjadi kesalahan: ' + (data.message || 'Unknown'));
      }
    } catch (e) {
      alert('Gagal menghubungi server.');
    } finally {
      btn.textContent = 'Perpanjang →';
      btn.disabled = false;
    }
  }

  // Close modal on overlay click
  document.getElementById('extendModal').addEventListener('click', function(e) {
    if (e.target === this) closeExtendModal();
  });
</script>
@endpush
