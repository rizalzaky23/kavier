<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>POS Master — Login</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --bg:        #0a0e1a;
      --surface:   #111827;
      --card:      rgba(255,255,255,0.04);
      --border:    rgba(255,255,255,0.08);
      --primary:   #6366f1;
      --primary-h: #818cf8;
      --text:      #f1f5f9;
      --muted:     #94a3b8;
      --error:     #f87171;
      --success:   #34d399;
    }

    body {
      font-family: 'Inter', sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }

    /* animated background orbs */
    .orb {
      position: fixed;
      border-radius: 50%;
      filter: blur(80px);
      opacity: 0.15;
      pointer-events: none;
      animation: float 8s ease-in-out infinite;
    }
    .orb-1 { width: 500px; height: 500px; background: #6366f1; top: -150px; left: -100px; animation-delay: 0s; }
    .orb-2 { width: 400px; height: 400px; background: #a855f7; bottom: -100px; right: -80px; animation-delay: 4s; }
    .orb-3 { width: 300px; height: 300px; background: #06b6d4; top: 40%; left: 40%; animation-delay: 2s; }

    @keyframes float {
      0%, 100% { transform: translateY(0) scale(1); }
      50%       { transform: translateY(-30px) scale(1.05); }
    }

    .login-container {
      position: relative;
      z-index: 10;
      width: 100%;
      max-width: 420px;
      padding: 20px;
    }

    .login-card {
      background: rgba(17, 24, 39, 0.8);
      backdrop-filter: blur(24px);
      border: 1px solid var(--border);
      border-radius: 24px;
      padding: 40px;
      box-shadow: 0 25px 50px rgba(0,0,0,0.5);
      animation: slideUp 0.6s cubic-bezier(0.16, 1, 0.3, 1) both;
    }

    @keyframes slideUp {
      from { opacity: 0; transform: translateY(30px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    .logo-wrap {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 32px;
    }

    .logo-icon {
      width: 48px;
      height: 48px;
      background: linear-gradient(135deg, #6366f1, #a855f7);
      border-radius: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 22px;
    }

    .logo-text { font-size: 20px; font-weight: 700; }
    .logo-sub  { font-size: 12px; color: var(--muted); margin-top: 2px; }

    h2 { font-size: 26px; font-weight: 700; margin-bottom: 6px; }
    .subtitle { font-size: 14px; color: var(--muted); margin-bottom: 30px; }

    .alert-error {
      background: rgba(248,113,113,0.12);
      border: 1px solid rgba(248,113,113,0.3);
      color: var(--error);
      border-radius: 10px;
      padding: 12px 16px;
      font-size: 13px;
      margin-bottom: 20px;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .form-group { margin-bottom: 18px; }

    label {
      display: block;
      font-size: 13px;
      font-weight: 500;
      color: var(--muted);
      margin-bottom: 8px;
    }

    .input-wrap {
      position: relative;
    }

    .input-icon {
      position: absolute;
      left: 14px;
      top: 50%;
      transform: translateY(-50%);
      color: var(--muted);
      font-size: 16px;
      pointer-events: none;
    }

    input[type="email"],
    input[type="password"],
    input[type="text"] {
      width: 100%;
      padding: 12px 14px 12px 42px;
      background: rgba(255,255,255,0.05);
      border: 1px solid var(--border);
      border-radius: 12px;
      color: var(--text);
      font-size: 14px;
      font-family: 'Inter', sans-serif;
      transition: border-color 0.2s, background 0.2s;
      outline: none;
    }

    input:focus {
      border-color: var(--primary);
      background: rgba(99,102,241,0.08);
    }

    input::placeholder { color: #4b5563; }

    .btn-primary {
      width: 100%;
      padding: 14px;
      background: linear-gradient(135deg, #6366f1, #8b5cf6);
      color: white;
      border: none;
      border-radius: 12px;
      font-size: 15px;
      font-weight: 600;
      font-family: 'Inter', sans-serif;
      cursor: pointer;
      margin-top: 8px;
      transition: opacity 0.2s, transform 0.1s;
      letter-spacing: 0.02em;
    }

    .btn-primary:hover  { opacity: 0.9; transform: translateY(-1px); }
    .btn-primary:active { transform: translateY(0); }

    .footer-note {
      text-align: center;
      margin-top: 24px;
      font-size: 12px;
      color: #374151;
    }
  </style>
</head>
<body>
  <div class="orb orb-1"></div>
  <div class="orb orb-2"></div>
  <div class="orb orb-3"></div>

  <div class="login-container">
    <div class="login-card">
      <div class="logo-wrap">
        <div class="logo-icon">🛡️</div>
        <div>
          <div class="logo-text">POS Master</div>
          <div class="logo-sub">License Management</div>
        </div>
      </div>

      <h2>Selamat Datang</h2>
      <p class="subtitle">Login sebagai Super Administrator</p>

      @if ($errors->any())
        <div class="alert-error">
          ⚠️ {{ $errors->first() }}
        </div>
      @endif

      @if (session('error'))
        <div class="alert-error">
          ⚠️ {{ session('error') }}
        </div>
      @endif

      <form method="POST" action="{{ route('master.login.post') }}">
        @csrf
        <div class="form-group">
          <label for="email">Email</label>
          <div class="input-wrap">
            <span class="input-icon">✉️</span>
            <input type="email" id="email" name="email"
                   value="{{ old('email') }}"
                   placeholder="admin@email.com" required autofocus>
          </div>
        </div>

        <div class="form-group">
          <label for="password">Password</label>
          <div class="input-wrap">
            <span class="input-icon">🔑</span>
            <input type="password" id="password" name="password"
                   placeholder="••••••••" required>
          </div>
        </div>

        <button type="submit" class="btn-primary">Masuk ke Dashboard →</button>
      </form>

      <p class="footer-note">POS License Server · Hanya untuk administrator</p>
    </div>
  </div>
</body>
</html>
