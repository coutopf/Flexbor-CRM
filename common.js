// ╔══════════════════════════════════════════════════════╗
// ║  Flexbor CRM — common.js                             ║
// ║  Utilitários partilhados entre comercial e gestor    ║
// ╚══════════════════════════════════════════════════════╝

// ── FORMATAÇÃO ──────────────────────────────────────────
function fmtDate(d) {
  if (!d) return '—';
  const p = d.split('-');
  return p.length === 3 ? `${p[2]}/${p[1]}/${p[0]}` : d;
}

function fmtEur(v) {
  return (v || 0).toLocaleString('pt-PT', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }) + ' €';
}

function fmtEurK(v) {
  if (v >= 1_000_000) return (v / 1_000_000).toFixed(1) + 'M€';
  if (v >= 1_000)     return Math.round(v / 1_000) + 'K€';
  return Math.round(v) + '€';
}

function tipoCls(t) {
  return { Presencial: 'bbg', Videochamada: 'bbl', Telefone: 'bbo' }[t] || 'bbgr';
}

function esc(s) {
  return (s || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function daysLeft(d) {
  if (!d) return null;
  const today = new Date(); today.setHours(0, 0, 0, 0);
  return Math.ceil((new Date(d) - today) / 86_400_000);
}

// ── TOAST ────────────────────────────────────────────────
function toast(msg, type = 'ok', dur = 2800) {
  const c = document.getElementById('toasts');
  if (!c) return;
  const t = document.createElement('div');
  t.className = `toast t${type}`;
  t.textContent = msg;
  c.appendChild(t);
  requestAnimationFrame(() => requestAnimationFrame(() => t.classList.add('on')));
  setTimeout(() => { t.classList.remove('on'); setTimeout(() => t.remove(), 300); }, dur);
}

// ── TEMA ─────────────────────────────────────────────────
function initTheme(defaultTheme = 'light') {
  const stored = localStorage.getItem('flexbor-theme') || defaultTheme;
  if (stored === 'dark') document.documentElement.classList.add('dark');
  else document.documentElement.classList.remove('dark');
  updateThemeBtn(stored === 'dark');
}

function toggleTheme() {
  const isDark = document.documentElement.classList.toggle('dark');
  localStorage.setItem('flexbor-theme', isDark ? 'dark' : 'light');
  updateThemeBtn(isDark);
}

function updateThemeBtn(isDark) {
  const btn = document.getElementById('theme-btn');
  if (btn) btn.innerHTML = isDark ? '☀ Claro' : '🌙 Escuro';
}

// ── SESSÃO ───────────────────────────────────────────────
function clearSession() {
  Object.keys(localStorage).forEach(k => {
    if (k.startsWith('sb-') || k.startsWith('supabase') || k.startsWith('flexbor-'))
      localStorage.removeItem(k);
  });
  Object.keys(sessionStorage).forEach(k => {
    if (k.startsWith('sb-') || k.startsWith('supabase'))
      sessionStorage.removeItem(k);
  });
  window.location.reload();
}

// ── MODAIS ───────────────────────────────────────────────
function closeModal(type) {
  const el = document.getElementById('mov-' + type);
  if (el) el.classList.remove('on');
}

// ── SKELETON SCREENS ─────────────────────────────────────
function skeletonRows(n = 5, cols = 4) {
  const cells = Array(cols).fill('<td><div class="skel"></div></td>').join('');
  return Array(n).fill(`<tr>${cells}</tr>`).join('');
}

function skeletonCards(n = 3) {
  return Array(n).fill(`
    <div style="padding:14px 18px;border-bottom:1px solid var(--b)">
      <div class="skel" style="width:60%;height:14px;margin-bottom:6px"></div>
      <div class="skel" style="width:35%;height:11px"></div>
    </div>`).join('');
}

// CSS para skeleton — injeta uma vez
(function injectSkeletonCSS() {
  if (document.getElementById('skeleton-css')) return;
  const s = document.createElement('style');
  s.id = 'skeleton-css';
  s.textContent = `
    .skel{background:linear-gradient(90deg,var(--s3) 25%,var(--s2) 50%,var(--s3) 75%);
      background-size:200% 100%;animation:skel-anim 1.4s ease infinite;
      border-radius:4px;height:12px;}
    @keyframes skel-anim{0%{background-position:200% 0}100%{background-position:-200% 0}}
  `;
  document.head.appendChild(s);
})();

// ── DEBOUNCE ─────────────────────────────────────────────
function debounce(fn, ms = 250) {
  let timer;
  return (...args) => { clearTimeout(timer); timer = setTimeout(() => fn(...args), ms); };
}

// ── DETALHE GENÉRICO (field card) ────────────────────────
function dfld(label, value) {
  return `<div style="background:var(--s2);border-radius:var(--r);padding:10px 13px">
    <div style="font-size:10px;color:var(--t3);text-transform:uppercase;letter-spacing:.4px;margin-bottom:4px;font-weight:700">${label}</div>
    <div style="font-size:13px;line-height:1.5">${value}</div>
  </div>`;
}
