// Fuzzy search powered by Fuse.js, loaded from a prebuilt index at /search-index.json
import Fuse from 'https://cdn.jsdelivr.net/npm/fuse.js@7.1.0/dist/fuse.mjs';

const base = (document.querySelector('link[rel="manifest"]')?.getAttribute('href') || '/manifest.webmanifest').replace('/manifest.webmanifest', '');

let fuse = null;
let docs = [];
let activeIdx = 0;
let lastResults = [];

async function loadIndex() {
  if (fuse) return;
  const res = await fetch(`${base}/search-index.json`);
  docs = await res.json();
  fuse = new Fuse(docs, {
    keys: [
      { name: 'title', weight: 0.4 },
      { name: 'category', weight: 0.15 },
      { name: 'tags', weight: 0.2 },
      { name: 'body', weight: 0.25 },
    ],
    threshold: 0.35,
    ignoreLocation: true,
    minMatchCharLength: 2,
    includeMatches: true,
  });
}

const overlay = document.getElementById('search-overlay');
const overlayInput = document.getElementById('overlay-search-input');
const results = document.getElementById('search-results');
const count = document.getElementById('search-count');
const headerInput = document.getElementById('global-search');

function openOverlay(prefill = '') {
  overlay?.classList.remove('hidden');
  overlay?.classList.add('flex');
  loadIndex().then(() => {
    overlayInput.value = prefill;
    overlayInput.focus();
    overlayInput.dispatchEvent(new Event('input'));
  });
}
function closeOverlay() {
  overlay?.classList.add('hidden');
  overlay?.classList.remove('flex');
}

function escapeHtml(s) {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
}

function highlight(text, indices) {
  if (!indices || !indices.length) return escapeHtml(text);
  let out = '';
  let last = 0;
  indices.forEach(([s, e]) => {
    out += escapeHtml(text.slice(last, s));
    out += '<mark class="search-hit">' + escapeHtml(text.slice(s, e + 1)) + '</mark>';
    last = e + 1;
  });
  out += escapeHtml(text.slice(last));
  return out;
}

function render(q) {
  if (!q || !q.trim()) {
    results.innerHTML = '<div class="p-4 text-[var(--color-muted)]">Start typing to search payloads, tools, ports, techniques…</div>';
    count.textContent = '';
    lastResults = [];
    return;
  }
  const hits = fuse.search(q, { limit: 40 });
  lastResults = hits;
  activeIdx = 0;
  count.textContent = `${hits.length} result${hits.length === 1 ? '' : 's'}`;
  if (!hits.length) {
    results.innerHTML = '<div class="p-4 text-[var(--color-muted)]">No matches.</div>';
    return;
  }
  results.innerHTML = hits.map((h, i) => {
    const d = h.item;
    const titleMatch = h.matches?.find((m) => m.key === 'title');
    const bodyMatch = h.matches?.find((m) => m.key === 'body');
    const snippet = bodyMatch ? buildSnippet(d.body, bodyMatch.indices) : (d.body.slice(0, 140) + (d.body.length > 140 ? '…' : ''));
    return `<a href="${base}/c/${d.category}/${d.slug}" class="search-item block px-3 py-2 rounded hover:bg-[var(--color-card)]" data-idx="${i}">
      <div class="flex items-center justify-between gap-2">
        <span class="font-medium">${titleMatch ? highlight(d.title, titleMatch.indices) : escapeHtml(d.title)}</span>
        <span class="text-[10px] uppercase tracking-wide text-[var(--color-muted)]">${d.category}</span>
      </div>
      <div class="text-xs text-[var(--color-muted)] line-clamp-2 mt-0.5">${snippet}</div>
    </a>`;
  }).join('');
  highlightActive();
}

function buildSnippet(body, indices) {
  if (!indices?.length) return escapeHtml(body.slice(0, 140));
  const first = indices[0];
  const start = Math.max(0, first[0] - 40);
  const end = Math.min(body.length, first[1] + 80);
  const slice = body.slice(start, end);
  const adjusted = indices
    .filter(([s, e]) => s >= start && e <= end)
    .map(([s, e]) => [s - start, e - start]);
  return (start > 0 ? '…' : '') + highlight(slice, adjusted) + (end < body.length ? '…' : '');
}

function highlightActive() {
  results.querySelectorAll('.search-item').forEach((el, i) => {
    if (i === activeIdx) {
      el.style.background = 'var(--color-card)';
      el.scrollIntoView({ block: 'nearest' });
    } else {
      el.style.background = '';
    }
  });
}

overlayInput?.addEventListener('input', (e) => render(e.target.value));
overlayInput?.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowDown') { e.preventDefault(); activeIdx = Math.min(activeIdx + 1, lastResults.length - 1); highlightActive(); }
  else if (e.key === 'ArrowUp') { e.preventDefault(); activeIdx = Math.max(activeIdx - 1, 0); highlightActive(); }
  else if (e.key === 'Enter') {
    const item = results.querySelectorAll('.search-item')[activeIdx];
    if (item) location.href = item.getAttribute('href');
  } else if (e.key === 'Escape') {
    closeOverlay();
  }
});

overlay?.addEventListener('click', (e) => { if (e.target === overlay) closeOverlay(); });

headerInput?.addEventListener('focus', () => { openOverlay(headerInput.value); headerInput.blur(); });
headerInput?.addEventListener('input', (e) => { openOverlay(e.target.value); });

document.addEventListener('keydown', (e) => {
  if (e.key === '/' && !['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) {
    e.preventDefault();
    openOverlay();
  }
  if ((e.key === 'k' || e.key === 'K') && (e.metaKey || e.ctrlKey)) {
    e.preventDefault();
    openOverlay();
  }
});
