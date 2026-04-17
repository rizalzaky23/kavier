/**
 * POS App — Web Frontend JS
 * Handles API calls, state, and UI rendering
 */

'use strict';

// ── Config ───────────────────────────────────────────────────────────────────
const API = {
  baseUrl: 'http://localhost:8000/api',

  getHeaders() {
    const token = localStorage.getItem('pos_token');
    return {
      'Content-Type':  'application/json',
      'Accept':        'application/json',
      ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    };
  },

  async get(path, params = {}) {
    const url = new URL(this.baseUrl + path);
    Object.entries(params).forEach(([k, v]) => v !== null && url.searchParams.set(k, v));
    const res = await fetch(url, { headers: this.getHeaders() });
    if (!res.ok) throw await res.json();
    return res.json();
  },

  async post(path, body = {}) {
    const res = await fetch(this.baseUrl + path, {
      method:  'POST',
      headers: this.getHeaders(),
      body:    JSON.stringify(body),
    });
    if (!res.ok) throw await res.json();
    return res.json();
  },

  async delete(path) {
    const res = await fetch(this.baseUrl + path, {
      method:  'DELETE',
      headers: this.getHeaders(),
    });
    if (!res.ok) throw await res.json();
    return res.json();
  },
};

// ── State ────────────────────────────────────────────────────────────────────
const State = {
  user:       JSON.parse(localStorage.getItem('pos_user') || 'null'),
  products:   [],
  categories: [],
  cart:       [],
  discount:   0,
  taxPct:     10,
  payMethod:  'cash',
  paidAmount: 0,
  selectedCat: null,
  searchQ:    '',

  get subtotal() { return this.cart.reduce((s, i) => s + i.price * i.qty, 0); },
  get tax()      { return this.subtotal * (this.taxPct / 100); },
  get total()    { return this.subtotal + this.tax - this.discount; },
  get change()   { return this.paidAmount - this.total; },
};

// ── Formatting ───────────────────────────────────────────────────────────────
const fmt = (n) =>
  new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(n);

// ── Toast ─────────────────────────────────────────────────────────────────────
function toast(msg, type = 'info') {
  const c = document.getElementById('toast-container') || (() => {
    const el = document.createElement('div');
    el.id = 'toast-container';
    el.className = 'toast-container';
    document.body.appendChild(el);
    return el;
  })();

  const icons = { success: '✅', error: '❌', info: 'ℹ️' };
  const t = document.createElement('div');
  t.className = `toast toast-${type}`;
  t.innerHTML = `<span>${icons[type]}</span><span>${msg}</span>`;
  c.appendChild(t);
  setTimeout(() => t.remove(), 3500);
}

// ── Auth ──────────────────────────────────────────────────────────────────────
async function login(email, password) {
  try {
    const data = await API.post('/auth/login', { email, password });
    localStorage.setItem('pos_token', data.token);
    localStorage.setItem('pos_user', JSON.stringify(data.user));
    State.user = data.user;
    window.location.href = 'kasir.html';
  } catch (err) {
    toast(err?.message || 'Login gagal. Periksa email/password.', 'error');
  }
}

async function logout() {
  try { await API.post('/auth/logout'); } catch (_) {}
  localStorage.removeItem('pos_token');
  localStorage.removeItem('pos_user');
  window.location.href = 'index.html';
}

function requireAuth() {
  if (!localStorage.getItem('pos_token')) {
    window.location.href = 'index.html';
    return false;
  }
  return true;
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
function renderSidebar(activePage) {
  if (!requireAuth()) return;
  const user = State.user || JSON.parse(localStorage.getItem('pos_user') || '{}');

  const pages = [
    { href: 'dashboard.html', icon: '📊', label: 'Dashboard' },
    { href: 'kasir.html',     icon: '🛒', label: 'Kasir'     },
    { href: 'products.html',  icon: '📦', label: 'Produk'    },
    { href: 'reports.html',   icon: '📈', label: 'Laporan'   },
  ];

  const nav = pages.map(p => `
    <a href="${p.href}" class="nav-item ${activePage === p.href ? 'active' : ''}">
      <span class="icon">${p.icon}</span> ${p.label}
    </a>`).join('');

  return `
    <div class="sidebar-header">
      <span class="logo-icon">🏪</span>
      <h1>POS App</h1>
    </div>
    <div class="user-badge">
      <div class="avatar">${(user.name || 'U')[0].toUpperCase()}</div>
      <div>
        <div class="name">${user.name || '-'}</div>
        <div class="role">${(user.role || '').toUpperCase()}</div>
      </div>
    </div>
    <nav class="sidebar-nav">${nav}</nav>
    <div class="sidebar-footer">
      <button class="btn-logout" onclick="logout()">🚪 Keluar</button>
    </div>`;
}

// ── Products API ──────────────────────────────────────────────────────────────
async function loadProducts(search = '', categoryId = null) {
  const data = await API.get('/products', {
    search:      search || null,
    category_id: categoryId,
    is_active:   true,
  });
  State.products = data.data || data;
  return State.products;
}

async function loadCategories() {
  const data = await API.get('/categories');
  State.categories = data.data;
  return State.categories;
}

// ── Cart logic ────────────────────────────────────────────────────────────────
function addToCart(productId) {
  const p = State.products.find(x => x.id === productId);
  if (!p || p.stock === 0) return;
  const existing = State.cart.find(i => i.id === productId);
  if (existing) {
    if (existing.qty < p.stock) existing.qty++;
  } else {
    State.cart.push({ id: p.id, name: p.name, price: parseFloat(p.price), qty: 1, maxStock: p.stock });
  }
  renderCart();
}

function removeFromCart(id) {
  State.cart = State.cart.filter(i => i.id !== id);
  renderCart();
}

function updateQty(id, delta) {
  const item = State.cart.find(i => i.id === id);
  if (!item) return;
  item.qty += delta;
  if (item.qty <= 0) removeFromCart(id);
  else if (item.qty > item.maxStock) item.qty = item.maxStock;
  else renderCart();
}

function clearCart() {
  State.cart = [];
  State.discount  = 0;
  State.paidAmount = 0;
  renderCart();
}

function renderCart() {
  const cartItems = document.getElementById('cart-items');
  const cartSummary = document.getElementById('cart-summary');
  const emptyCart   = document.getElementById('cart-empty');
  const checkoutBtn = document.getElementById('btn-checkout');

  if (!cartItems) return;

  if (State.cart.length === 0) {
    cartItems.innerHTML = '';
    if (emptyCart)   emptyCart.style.display = 'flex';
    if (cartSummary) cartSummary.style.display = 'none';
    if (checkoutBtn) checkoutBtn.disabled = true;
    return;
  }

  if (emptyCart)   emptyCart.style.display = 'none';
  if (cartSummary) cartSummary.style.display = 'block';
  if (checkoutBtn) checkoutBtn.disabled = false;

  cartItems.innerHTML = State.cart.map(item => `
    <div class="cart-item">
      <div class="cart-item-info">
        <div class="cart-item-name">${item.name}</div>
        <div class="cart-item-price">${fmt(item.price)}</div>
      </div>
      <div class="qty-ctrl">
        <button class="qty-btn" onclick="updateQty(${item.id}, -1)">−</button>
        <span class="qty-val">${item.qty}</span>
        <button class="qty-btn" onclick="updateQty(${item.id}, 1)">+</button>
      </div>
      <span class="cart-delete" onclick="removeFromCart(${item.id})" title="Hapus">🗑️</span>
    </div>
  `).join('');

  if (cartSummary) {
    cartSummary.innerHTML = `
      <div class="summary-row"><span class="label">Subtotal</span><span>${fmt(State.subtotal)}</span></div>
      <div class="summary-row"><span class="label">Pajak (${State.taxPct}%)</span><span>${fmt(State.tax)}</span></div>
      <div class="summary-row"><span class="label">Diskon</span><span style="color:var(--success)">− ${fmt(State.discount)}</span></div>
      <div class="summary-row total"><span>TOTAL</span><span>${fmt(State.total)}</span></div>
    `;
  }
}

// ── Checkout ──────────────────────────────────────────────────────────────────
async function checkout(paidAmount, payMethod, discount) {
  if (State.cart.length === 0) return;
  State.paidAmount = paidAmount;
  State.payMethod  = payMethod;
  State.discount   = discount;

  if (paidAmount < State.total) {
    toast('Jumlah bayar kurang dari total!', 'error');
    return;
  }

  try {
    const res = await API.post('/transactions', {
      items:          State.cart.map(i => ({ product_id: i.id, quantity: i.qty })),
      discount:       State.discount,
      paid_amount:    paidAmount,
      payment_method: payMethod,
      tax_percentage: State.taxPct,
    });

    const tx = res.data;
    closeModal('checkout-modal');
    showSuccessModal(tx, paidAmount);
    clearCart();
    await loadProducts(State.searchQ, State.selectedCat);
    renderProducts();
  } catch (err) {
    toast(err?.message || 'Transaksi gagal!', 'error');
  }
}

function showSuccessModal(tx, paid) {
  const change = paid - parseFloat(tx.total);
  const html = `
    <div style="text-align:center;padding:24px 0">
      <div style="font-size:64px;margin-bottom:16px">✅</div>
      <h2 style="font-size:22px;font-weight:700;margin-bottom:6px">Transaksi Berhasil!</h2>
      <p style="color:var(--text-secondary);margin-bottom:20px">${tx.invoice_number}</p>
      <div class="card" style="text-align:left;margin-bottom:20px">
        <div class="summary-row"><span class="label">Total</span><span style="font-weight:700">${fmt(tx.total)}</span></div>
        <div class="summary-row"><span class="label">Dibayar</span><span>${fmt(paid)}</span></div>
        <div class="summary-row"><span class="label">Kembalian</span><span style="color:var(--success);font-weight:600">${fmt(change)}</span></div>
      </div>
      <button class="btn btn-primary btn-block btn-lg" onclick="closeModal('success-modal')">Transaksi Baru</button>
    </div>`;

  showModal('success-modal', '', html, false);
}

// ── Render products ───────────────────────────────────────────────────────────
function renderProducts() {
  const grid = document.getElementById('product-grid');
  if (!grid) return;

  if (State.products.length === 0) {
    grid.innerHTML = '<p style="padding:32px;color:var(--text-secondary)">Tidak ada produk.</p>';
    return;
  }

  grid.innerHTML = State.products.map(p => {
    const noStock = p.stock === 0;
    const isLow   = !noStock && p.stock <= (p.low_stock_threshold || 5);
    const stockLabel = noStock ? '❌ Habis' : isLow
        ? `⚠️ Sisa ${p.stock}` : `✓ Stok: ${p.stock}`;

    return `
      <div class="product-card ${noStock ? 'out-of-stock' : ''}" 
           onclick="${noStock ? '' : `addToCart(${p.id})`}"
           title="${noStock ? 'Stok habis' : 'Klik untuk tambah ke keranjang'}">
        <div class="product-img">
          ${p.image_url && !p.image_url.includes('no-image')
            ? `<img src="${p.image_url}" alt="${p.name}" onerror="this.parentNode.textContent='🍽️'">`
            : '🍽️'}
        </div>
        <div class="product-info">
          <div class="product-name" title="${p.name}">${p.name}</div>
          <div class="product-price">${fmt(p.price)}</div>
          <div class="product-stock ${noStock ? 'none' : isLow ? 'low' : ''}">${stockLabel}</div>
        </div>
      </div>`;
  }).join('');
}

// ── Category chip render ──────────────────────────────────────────────────────
function renderCategoryChips(containerId, selected, onChange) {
  const el = document.getElementById(containerId);
  if (!el) return;

  const all = [{ id: null, name: 'Semua' }, ...State.categories];
  el.innerHTML = all.map(c => `
    <span class="chip ${selected === c.id ? 'active' : ''}"
          onclick="(${onChange.toString()})(${c.id === null ? 'null' : c.id})">
      ${c.name}
    </span>`).join('');
}

// ── Modal helpers ─────────────────────────────────────────────────────────────
function showModal(id, title, bodyHTML, showClose = true) {
  document.querySelectorAll(`#${id}`).forEach(el => el.remove());

  const modal = document.createElement('div');
  modal.className = 'modal-overlay';
  modal.id = id;
  modal.innerHTML = `
    <div class="modal" onclick="event.stopPropagation()">
      ${title ? `<div class="modal-header">
        <span class="modal-title">${title}</span>
        ${showClose ? `<button class="btn-close" onclick="closeModal('${id}')">×</button>` : ''}
      </div>` : ''}
      <div class="modal-body">${bodyHTML}</div>
    </div>`;

  if (showClose) modal.addEventListener('click', () => closeModal(id));
  document.body.appendChild(modal);
}

function closeModal(id) {
  document.getElementById(id)?.remove();
}

// ── Report helpers ────────────────────────────────────────────────────────────
async function loadReport(period = 'daily') {
  const [summary, top] = await Promise.all([
    API.get('/reports/summary', { period }),
    API.get('/reports/top-products', { period }),
  ]);
  return { summary: summary.data, topProducts: top.data };
}

// Export
function exportReport(period = 'daily') {
  const token = localStorage.getItem('pos_token');
  const url   = `${API.baseUrl}/reports/export?period=${period}`;
  // Open in new tab (browser will trigger download with auth header via fetch won't work due to anchor limitation)
  // Better: use hidden form to include auth
  const a = document.createElement('a');
  a.href  = url + `&token=${token}`;
  a.click();
}
