<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>@yield('title', 'POS Master Panel')</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --bg:       #080c14;
      --surface:  #0f1623;
      --card:     #141d2b;
      --border:   rgba(255,255,255,0.07);
      --primary:  #6366f1;
      --pri-light:#818cf8;
      --success:  #10b981;
      --warning:  #f59e0b;
      --danger:   #ef4444;
      --info:     #06b6d4;
      --text:     #e2e8f0;
      --muted:    #64748b;
      --sidebar-w: 260px;
    }

    html, body { height: 100%; }

    body {
      font-family: 'Inter', sans-serif;
      background: var(--bg);
      color: var(--text);
      display: flex;
    }

    /* ── Sidebar ─────────────────────────────── */
    .sidebar {
      width: var(--sidebar-w);
      min-height: 100vh;
      background: var(--surface);
      border-right: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      position: fixed;
      top: 0; left: 0; bottom: 0;
      z-index: 100;
    }

    .sidebar-brand {
      padding: 24px 20px;
      display: flex;
      align-items: center;
      gap: 12px;
      border-bottom: 1px solid var(--border);
    }

    .brand-icon {
      width: 42px; height: 42px;
      background: linear-gradient(135deg, #6366f1, #a855f7);
      border-radius: 12px;
      display: flex; align-items: center; justify-content: center;
      font-size: 20px;
      flex-shrink: 0;
    }

    .brand-name { font-size: 16px; font-weight: 700; }
    .brand-sub  { font-size: 11px; color: var(--muted); margin-top: 1px; }

    .sidebar-nav { flex: 1; padding: 16px 12px; overflow-y: auto; }

    .nav-label {
      font-size: 10px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--muted);
      padding: 16px 8px 8px;
    }

    .nav-item {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 10px 12px;
      border-radius: 10px;
      color: var(--muted);
      text-decoration: none;
      font-size: 14px;
      font-weight: 500;
      transition: all 0.2s;
      margin-bottom: 2px;
    }

    .nav-item:hover {
      background: rgba(99,102,241,0.1);
      color: var(--pri-light);
    }

    .nav-item.active {
      background: rgba(99,102,241,0.15);
      color: var(--primary);
      font-weight: 600;
    }

    .nav-icon { font-size: 16px; width: 20px; text-align: center; }

    .sidebar-footer {
      padding: 16px 12px;
      border-top: 1px solid var(--border);
    }

    .admin-info {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 10px;
      border-radius: 10px;
      margin-bottom: 8px;
    }

    .admin-avatar {
      width: 36px; height: 36px;
      background: linear-gradient(135deg, #6366f1, #a855f7);
      border-radius: 10px;
      display: flex; align-items: center; justify-content: center;
      font-size: 14px; font-weight: 700;
      flex-shrink: 0;
    }

    .admin-name  { font-size: 13px; font-weight: 600; }
    .admin-role  { font-size: 11px; color: var(--primary); }

    .btn-logout {
      display: flex;
      align-items: center;
      gap: 8px;
      width: 100%;
      padding: 9px 12px;
      background: rgba(239,68,68,0.1);
      color: #f87171;
      border: 1px solid rgba(239,68,68,0.2);
      border-radius: 10px;
      font-size: 13px;
      font-weight: 500;
      font-family: 'Inter', sans-serif;
      cursor: pointer;
      text-decoration: none;
      justify-content: center;
      transition: all 0.2s;
    }
    .btn-logout:hover { background: rgba(239,68,68,0.2); }

    /* ── Main content ───────────────────────── */
    .main {
      margin-left: var(--sidebar-w);
      flex: 1;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }

    .topbar {
      padding: 20px 32px;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      background: var(--surface);
      position: sticky;
      top: 0;
      z-index: 50;
    }

    .page-title { font-size: 20px; font-weight: 700; }
    .page-sub   { font-size: 13px; color: var(--muted); margin-top: 2px; }

    .topbar-right { display: flex; align-items: center; gap: 12px; }

    .time-badge {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 6px 12px;
      font-size: 12px;
      color: var(--muted);
    }

    .content { padding: 32px; flex: 1; }

    /* ── Alert/Toast ───────────────────────── */
    .alert {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 14px 16px;
      border-radius: 12px;
      font-size: 14px;
      margin-bottom: 24px;
    }
    .alert-success { background: rgba(16,185,129,0.1); border: 1px solid rgba(16,185,129,0.25); color: #34d399; }
    .alert-error   { background: rgba(239,68,68,0.1);  border: 1px solid rgba(239,68,68,0.25);  color: #f87171; }
    .alert-warning { background: rgba(245,158,11,0.1); border: 1px solid rgba(245,158,11,0.25); color: #fbbf24; }

    /* ── Cards ─────────────────────────────── */
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 24px;
    }

    .card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
    }

    .card-title { font-size: 16px; font-weight: 600; }

    /* ── Stat cards ─────────────────────────── */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 28px;
    }

    .stat-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 20px;
      position: relative;
      overflow: hidden;
      transition: transform 0.2s, border-color 0.2s;
    }

    .stat-card:hover { transform: translateY(-2px); }
    .stat-card::before {
      content: '';
      position: absolute;
      top: 0; left: 0; right: 0;
      height: 3px;
      border-radius: 16px 16px 0 0;
    }
    .stat-card.c-primary::before  { background: var(--primary); }
    .stat-card.c-success::before  { background: var(--success); }
    .stat-card.c-warning::before  { background: var(--warning); }
    .stat-card.c-danger::before   { background: var(--danger); }
    .stat-card.c-info::before     { background: var(--info); }

    .stat-icon {
      font-size: 28px;
      margin-bottom: 12px;
    }

    .stat-value { font-size: 32px; font-weight: 800; margin-bottom: 4px; }
    .stat-label { font-size: 13px; color: var(--muted); }

    /* ── Table ─────────────────────────────── */
    .table-wrap { overflow-x: auto; }

    table { width: 100%; border-collapse: collapse; }

    thead th {
      text-align: left;
      padding: 12px 16px;
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--muted);
      border-bottom: 1px solid var(--border);
    }

    tbody tr { transition: background 0.15s; }
    tbody tr:hover { background: rgba(255,255,255,0.02); }

    tbody td {
      padding: 14px 16px;
      font-size: 14px;
      border-bottom: 1px solid rgba(255,255,255,0.04);
      vertical-align: middle;
    }

    /* Badges */
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 500;
    }
    .badge-success { background: rgba(16,185,129,0.15);  color: #34d399; }
    .badge-danger  { background: rgba(239,68,68,0.15);   color: #f87171; }
    .badge-warning { background: rgba(245,158,11,0.15);  color: #fbbf24; }
    .badge-muted   { background: rgba(100,116,139,0.15); color: var(--muted); }
    .badge-info    { background: rgba(6,182,212,0.15);   color: #22d3ee; }

    /* Buttons */
    .btn {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 9px 18px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 600;
      font-family: 'Inter', sans-serif;
      cursor: pointer;
      text-decoration: none;
      border: none;
      transition: all 0.2s;
      white-space: nowrap;
    }
    .btn-sm { padding: 6px 12px; font-size: 12px; border-radius: 8px; }

    .btn-primary { background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; }
    .btn-primary:hover { opacity: 0.85; transform: translateY(-1px); }

    .btn-success { background: rgba(16,185,129,0.15); color: #34d399; border: 1px solid rgba(16,185,129,0.25); }
    .btn-success:hover { background: rgba(16,185,129,0.25); }

    .btn-warning { background: rgba(245,158,11,0.15); color: #fbbf24; border: 1px solid rgba(245,158,11,0.25); }
    .btn-warning:hover { background: rgba(245,158,11,0.25); }

    .btn-danger  { background: rgba(239,68,68,0.15);  color: #f87171; border: 1px solid rgba(239,68,68,0.25); }
    .btn-danger:hover  { background: rgba(239,68,68,0.25); }

    .btn-ghost   { background: transparent; color: var(--muted); border: 1px solid var(--border); }
    .btn-ghost:hover { color: var(--text); border-color: rgba(255,255,255,0.2); }

    /* Forms */
    .form-group { margin-bottom: 20px; }
    .form-label { display: block; font-size: 13px; font-weight: 500; color: var(--muted); margin-bottom: 8px; }

    .form-control {
      width: 100%;
      padding: 11px 14px;
      background: rgba(255,255,255,0.04);
      border: 1px solid var(--border);
      border-radius: 10px;
      color: var(--text);
      font-size: 14px;
      font-family: 'Inter', sans-serif;
      outline: none;
      transition: border-color 0.2s, background 0.2s;
    }
    .form-control:focus {
      border-color: var(--primary);
      background: rgba(99,102,241,0.06);
    }
    .form-control::placeholder { color: #374151; }

    select.form-control option { background: #1f2937; }

    .form-grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }

    /* Toggle switch */
    .switch-wrap {
      display: flex; align-items: center; gap: 12px;
    }
    .switch { position: relative; display: inline-block; width: 46px; height: 26px; }
    .switch input { opacity: 0; width: 0; height: 0; }
    .slider {
      position: absolute; cursor: pointer;
      top: 0; left: 0; right: 0; bottom: 0;
      background: #1f2937;
      border-radius: 26px;
      transition: 0.3s;
      border: 1px solid var(--border);
    }
    .slider::before {
      content: '';
      position: absolute;
      height: 18px; width: 18px;
      left: 3px; bottom: 3px;
      background: var(--muted);
      border-radius: 50%;
      transition: 0.3s;
    }
    input:checked + .slider { background: rgba(99,102,241,0.3); border-color: var(--primary); }
    input:checked + .slider::before { transform: translateX(20px); background: var(--primary); }

    /* Pagination */
    .pagination { display: flex; gap: 6px; justify-content: center; margin-top: 24px; }
    .pagination a, .pagination span {
      padding: 7px 12px;
      border-radius: 8px;
      font-size: 13px;
      text-decoration: none;
      color: var(--muted);
      background: var(--card);
      border: 1px solid var(--border);
    }
    .pagination .active span { background: var(--primary); color: white; border-color: var(--primary); }
    .pagination a:hover { color: var(--text); border-color: rgba(255,255,255,0.2); }

    /* Search & filter bar */
    .toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 20px; }
    .toolbar-search {
      flex: 1; min-width: 200px;
      display: flex; gap: 0;
    }
    .search-input {
      flex: 1;
      padding: 10px 14px;
      background: rgba(255,255,255,0.04);
      border: 1px solid var(--border);
      border-radius: 10px 0 0 10px;
      color: var(--text);
      font-size: 14px;
      font-family: 'Inter', sans-serif;
      outline: none;
    }
    .search-input:focus { border-color: var(--primary); }
    .search-btn {
      padding: 10px 16px;
      background: var(--primary);
      border: none;
      border-radius: 0 10px 10px 0;
      color: white;
      cursor: pointer;
      font-size: 14px;
    }

    .filter-select {
      padding: 10px 12px;
      background: rgba(255,255,255,0.04);
      border: 1px solid var(--border);
      border-radius: 10px;
      color: var(--text);
      font-size: 13px;
      font-family: 'Inter', sans-serif;
      outline: none;
    }

    /* Modal */
    .modal-overlay {
      position: fixed; inset: 0; z-index: 1000;
      background: rgba(0,0,0,0.7);
      display: none;
      align-items: center;
      justify-content: center;
    }
    .modal-overlay.open { display: flex; }
    .modal {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 28px;
      width: 100%;
      max-width: 420px;
      animation: slideUp 0.3s cubic-bezier(0.16,1,0.3,1) both;
    }
    .modal-title { font-size: 18px; font-weight: 700; margin-bottom: 8px; }
    .modal-sub   { font-size: 13px; color: var(--muted); margin-bottom: 24px; }
    .modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px; }

    @keyframes slideUp {
      from { opacity: 0; transform: translateY(20px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    /* Responsive */
    @media (max-width: 768px) {
      .sidebar { display: none; }
      .main { margin-left: 0; }
      .content { padding: 20px; }
      .form-grid-2 { grid-template-columns: 1fr; }
    }
  </style>
  @stack('styles')
</head>
<body>

<!-- Sidebar -->
<aside class="sidebar">
  <div class="sidebar-brand">
    <div class="brand-icon">🛡️</div>
    <div>
      <div class="brand-name">POS Master</div>
      <div class="brand-sub">License Management</div>
    </div>
  </div>

  <nav class="sidebar-nav">
    <div class="nav-label">Menu Utama</div>

    <a href="{{ route('master.dashboard') }}"
       class="nav-item {{ request()->routeIs('master.dashboard') ? 'active' : '' }}">
      <span class="nav-icon">📊</span> Dashboard
    </a>

    <a href="{{ route('master.users.index') }}"
       class="nav-item {{ request()->routeIs('master.users.*') ? 'active' : '' }}">
      <span class="nav-icon">👥</span> Kelola User
    </a>
  </nav>

  <div class="sidebar-footer">
    <div class="admin-info">
      <div class="admin-avatar">{{ strtoupper(substr(session('master_admin_name', 'A'), 0, 1)) }}</div>
      <div>
        <div class="admin-name">{{ session('master_admin_name', 'Admin') }}</div>
        <div class="admin-role">Super Admin</div>
      </div>
    </div>
    <a href="{{ route('master.logout') }}" class="btn-logout">🚪 Keluar</a>
  </div>
</aside>

<!-- Main -->
<main class="main">
  <div class="topbar">
    <div>
      <div class="page-title">@yield('page-title', 'Dashboard')</div>
      <div class="page-sub">@yield('page-sub', '')</div>
    </div>
    <div class="topbar-right">
      <div class="time-badge" id="clock">--:--:--</div>
    </div>
  </div>

  <div class="content">
    @if (session('success'))
      <div class="alert alert-success">✅ {{ session('success') }}</div>
    @endif
    @if (session('error'))
      <div class="alert alert-error">❌ {{ session('error') }}</div>
    @endif

    @yield('content')
  </div>
</main>

<script>
  // Live clock
  function updateClock() {
    const now = new Date();
    document.getElementById('clock').textContent =
      now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  }
  setInterval(updateClock, 1000);
  updateClock();
</script>
@stack('scripts')
</body>
</html>
