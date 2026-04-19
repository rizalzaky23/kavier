@extends('master.layout')

@section('title', 'Edit User — POS Master')
@section('page-title', 'Edit User')
@section('page-sub', '{{ $user->name }} — {{ $user->email }}')

@section('content')

<div class="card" style="max-width:700px">

  <!-- Status header -->
  <div style="display:flex;align-items:center;gap:16px;margin-bottom:28px;padding-bottom:20px;border-bottom:1px solid var(--border)">
    <div style="width:52px;height:52px;background:linear-gradient(135deg,#6366f1,#a855f7);border-radius:14px;display:flex;align-items:center;justify-content:center;font-size:22px;font-weight:700">
      {{ strtoupper(substr($user->name,0,1)) }}
    </div>
    <div>
      <div style="font-size:18px;font-weight:700">{{ $user->name }}</div>
      <div style="font-size:13px;color:var(--muted)">{{ $user->email }}</div>
    </div>
    <div style="margin-left:auto">
      @php $label = $user->statusLabel(); @endphp
      @if(str_contains($label, 'Aktif') && !str_contains($label, 'Hampir'))
        <span class="badge badge-success" style="font-size:13px;padding:8px 14px">✅ Aktif</span>
      @elseif(str_contains($label, 'Hampir'))
        <span class="badge badge-warning" style="font-size:13px;padding:8px 14px">⚠️ {{ $label }}</span>
      @elseif(str_contains($label, 'Expired'))
        <span class="badge badge-danger" style="font-size:13px;padding:8px 14px">❌ Expired</span>
      @else
        <span class="badge badge-muted" style="font-size:13px;padding:8px 14px">{{ $label }}</span>
      @endif
    </div>
  </div>

  <form method="POST" action="{{ route('master.users.update', $user) }}">
    @csrf @method('PUT')

    <div class="form-grid-2">
      <div class="form-group">
        <label class="form-label">Nama Lengkap *</label>
        <input type="text" name="name" class="form-control"
               value="{{ old('name', $user->name) }}" required>
        @error('name') <span style="color:var(--danger);font-size:12px">{{ $message }}</span> @enderror
      </div>
      <div class="form-group">
        <label class="form-label">Nama Toko</label>
        <input type="text" name="store_name" class="form-control"
               value="{{ old('store_name', $user->store_name) }}" placeholder="-">
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Email *</label>
      <input type="email" name="email" class="form-control"
             value="{{ old('email', $user->email) }}" required>
      @error('email') <span style="color:var(--danger);font-size:12px">{{ $message }}</span> @enderror
    </div>

    <div style="background:rgba(99,102,241,0.06);border:1px solid rgba(99,102,241,0.15);border-radius:12px;padding:20px;margin-bottom:20px">
      <div style="font-size:13px;font-weight:600;margin-bottom:16px;color:var(--pri-light)">
        📅 Periode Lisensi
      </div>

      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px">
        @foreach([
          ['label'=>'+7 Hari',  'days'=>7],
          ['label'=>'+14 Hari', 'days'=>14],
          ['label'=>'+30 Hari', 'days'=>30],
          ['label'=>'+90 Hari', 'days'=>90],
          ['label'=>'+180 Hari','days'=>180],
          ['label'=>'+1 Tahun', 'days'=>365],
        ] as $p)
          <button type="button" class="btn btn-ghost btn-sm"
                  onclick="addDays({{ $p['days'] }})">{{ $p['label'] }}</button>
        @endforeach
      </div>

      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">Tanggal Mulai</label>
          <input type="date" name="license_start" id="license_start" class="form-control"
                 value="{{ old('license_start', $user->license_start?->toDateString()) }}">
        </div>
        <div class="form-group">
          <label class="form-label">Tanggal Berakhir</label>
          <input type="date" name="license_end" id="license_end" class="form-control"
                 value="{{ old('license_end', $user->license_end?->toDateString()) }}">
          @error('license_end') <span style="color:var(--danger);font-size:12px">{{ $message }}</span> @enderror
        </div>
      </div>
    </div>

    <div style="background:rgba(255,255,255,0.02);border:1px solid var(--border);border-radius:12px;padding:20px;margin-bottom:20px">
      <div style="font-size:13px;font-weight:600;margin-bottom:16px;color:var(--muted)">
        🔐 Ganti Password (kosongkan jika tidak ingin mengubah)
      </div>
      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">Password Baru</label>
          <input type="password" name="password" class="form-control" placeholder="Min. 6 karakter">
          @error('password') <span style="color:var(--danger);font-size:12px">{{ $message }}</span> @enderror
        </div>
        <div class="form-group">
          <label class="form-label">Konfirmasi Password</label>
          <input type="password" name="password_confirmation" class="form-control" placeholder="Ulangi password baru">
        </div>
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Status Akun</label>
      <div class="switch-wrap">
        <label class="switch">
          <input type="checkbox" name="is_active" value="1"
                 {{ old('is_active', $user->is_active) ? 'checked' : '' }}>
          <span class="slider"></span>
        </label>
        <span style="font-size:14px">Aktif</span>
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Catatan</label>
      <input type="text" name="notes" class="form-control"
             value="{{ old('notes', $user->notes) }}" placeholder="Catatan internal...">
    </div>

    <div style="display:flex;gap:12px;justify-content:flex-end;margin-top:8px">
      <a href="{{ route('master.users.index') }}" class="btn btn-ghost">Batal</a>
      <button type="submit" class="btn btn-primary">Simpan Perubahan →</button>
    </div>
  </form>
</div>

@endsection

@push('scripts')
<script>
  function addDays(d) {
    const endEl = document.getElementById('license_end');
    const base  = endEl.value || new Date().toISOString().slice(0,10);
    const end   = new Date(base);
    end.setDate(end.getDate() + d);
    endEl.value = end.toISOString().slice(0,10);
  }
</script>
@endpush
