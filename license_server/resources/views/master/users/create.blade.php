@extends('master.layout')

@section('title', 'Tambah User — POS Master')
@section('page-title', 'Tambah User Baru')
@section('page-sub', 'Buat akun user POS dengan periode lisensi')

@section('content')

<div class="card" style="max-width:700px">
  <form method="POST" action="{{ route('master.users.store') }}">
    @csrf

    <div class="form-grid-2">
      <div class="form-group">
        <label class="form-label">Nama Lengkap *</label>
        <input type="text" name="name" class="form-control"
               value="{{ old('name') }}" placeholder="Budi Santoso" required>
        @error('name') <span style="color:var(--danger);font-size:12px">{{ $message }}</span> @enderror
      </div>

      <div class="form-group">
        <label class="form-label">Nama Toko</label>
        <input type="text" name="store_name" class="form-control"
               value="{{ old('store_name') }}" placeholder="Toko Maju Jaya">
        @error('store_name') <span style="color:var(--danger);font-size:12px">{{ $message }}</span> @enderror
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Email *</label>
      <input type="email" name="email" class="form-control"
             value="{{ old('email') }}" placeholder="user@toko.com" required>
      @error('email') <span style="color:var(--danger);font-size:12px">{{ $message }}</span> @enderror
    </div>

    <div class="form-grid-2">
      <div class="form-group">
        <label class="form-label">Password *</label>
        <input type="password" name="password" class="form-control"
               placeholder="Minimal 6 karakter" required>
        @error('password') <span style="color:var(--danger);font-size:12px">{{ $message }}</span> @enderror
      </div>
      <div class="form-group">
        <label class="form-label">Konfirmasi Password *</label>
        <input type="password" name="password_confirmation" class="form-control"
               placeholder="Ulangi password" required>
      </div>
    </div>

    <div style="background:rgba(99,102,241,0.06);border:1px solid rgba(99,102,241,0.15);border-radius:12px;padding:20px;margin-bottom:20px">
      <div style="font-size:13px;font-weight:600;margin-bottom:16px;color:var(--pri-light)">
        📅 Periode Lisensi
      </div>

      <!-- Quick presets -->
      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px">
        @foreach([
          ['label'=>'7 Hari',   'days'=>7],
          ['label'=>'14 Hari',  'days'=>14],
          ['label'=>'1 Bulan',  'days'=>30],
          ['label'=>'3 Bulan',  'days'=>90],
          ['label'=>'6 Bulan',  'days'=>180],
          ['label'=>'1 Tahun',  'days'=>365],
        ] as $p)
          <button type="button" class="btn btn-ghost btn-sm"
                  onclick="setPreset({{ $p['days'] }})">{{ $p['label'] }}</button>
        @endforeach
      </div>

      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">Tanggal Mulai</label>
          <input type="date" name="license_start" id="license_start" class="form-control"
                 value="{{ old('license_start', date('Y-m-d')) }}">
        </div>
        <div class="form-group">
          <label class="form-label">Tanggal Berakhir</label>
          <input type="date" name="license_end" id="license_end" class="form-control"
                 value="{{ old('license_end') }}">
          @error('license_end') <span style="color:var(--danger);font-size:12px">{{ $message }}</span> @enderror
        </div>
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Status Akun</label>
      <div class="switch-wrap">
        <label class="switch">
          <input type="checkbox" name="is_active" value="1"
                 {{ old('is_active', '1') ? 'checked' : '' }}>
          <span class="slider"></span>
        </label>
        <span style="font-size:14px">Aktif</span>
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Catatan (opsional)</label>
      <input type="text" name="notes" class="form-control"
             value="{{ old('notes') }}" placeholder="Catatan internal...">
    </div>

    <div style="display:flex;gap:12px;justify-content:flex-end;margin-top:8px">
      <a href="{{ route('master.users.index') }}" class="btn btn-ghost">Batal</a>
      <button type="submit" class="btn btn-primary">Simpan User →</button>
    </div>
  </form>
</div>

@endsection

@push('scripts')
<script>
  function setPreset(days) {
    const start = document.getElementById('license_start').value || new Date().toISOString().slice(0,10);
    const end   = new Date(start);
    end.setDate(end.getDate() + days);
    document.getElementById('license_end').value = end.toISOString().slice(0,10);
  }
</script>
@endpush
