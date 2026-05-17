// Live variable substitution: wraps {{TOKEN}} occurrences in code blocks
// and updates them when the variable bar inputs change.

(function () {
  const DEFAULTS = { RHOST: '{{RHOST}}', RPORT: '{{RPORT}}', LHOST: '{{LHOST}}', LPORT: '{{LPORT}}', USER: '{{USER}}', DOMAIN: '{{DOMAIN}}' };
  const STORAGE_KEY = 'pc-vars';

  function loadVars() {
    try { return { ...DEFAULTS, ...JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}') }; }
    catch { return { ...DEFAULTS }; }
  }
  function saveVars(v) {
    const trimmed = {};
    for (const k of Object.keys(DEFAULTS)) if (v[k] && v[k] !== DEFAULTS[k]) trimmed[k] = v[k];
    localStorage.setItem(STORAGE_KEY, JSON.stringify(trimmed));
  }

  const vars = loadVars();

  // Hydrate inputs
  document.querySelectorAll('.var-input').forEach((el) => {
    const k = el.dataset.var;
    if (vars[k] && vars[k] !== DEFAULTS[k]) el.value = vars[k];
  });

  // Walk all code blocks, replace {{TOKEN}} with a span we can re-render
  function tokenizeCodeBlocks() {
    const codes = document.querySelectorAll('pre code, :not(pre) > code');
    const pattern = /\{\{(RHOST|RPORT|LHOST|LPORT|USER|DOMAIN)\}\}/g;
    codes.forEach((code) => {
      if (code.dataset.tokenized) return;
      const walker = document.createTreeWalker(code, NodeFilter.SHOW_TEXT, null);
      const nodes = [];
      while (walker.nextNode()) nodes.push(walker.currentNode);
      nodes.forEach((node) => {
        if (!pattern.test(node.nodeValue)) return;
        pattern.lastIndex = 0;
        const frag = document.createDocumentFragment();
        let last = 0;
        const text = node.nodeValue;
        let m;
        while ((m = pattern.exec(text)) !== null) {
          if (m.index > last) frag.appendChild(document.createTextNode(text.slice(last, m.index)));
          const span = document.createElement('span');
          span.className = 'var-token';
          span.dataset.var = m[1];
          span.textContent = vars[m[1]] || `{{${m[1]}}}`;
          frag.appendChild(span);
          last = m.index + m[0].length;
        }
        if (last < text.length) frag.appendChild(document.createTextNode(text.slice(last)));
        node.parentNode.replaceChild(frag, node);
      });
      code.dataset.tokenized = '1';
    });
  }

  function updateTokens() {
    document.querySelectorAll('.var-token').forEach((el) => {
      const k = el.dataset.var;
      el.textContent = vars[k] || `{{${k}}}`;
    });
  }

  document.querySelectorAll('.var-input').forEach((el) => {
    el.addEventListener('input', (e) => {
      const k = e.target.dataset.var;
      vars[k] = e.target.value || DEFAULTS[k];
      saveVars(vars);
      updateTokens();
    });
  });

  document.getElementById('vars-clear')?.addEventListener('click', () => {
    document.querySelectorAll('.var-input').forEach((el) => {
      el.value = '';
      vars[el.dataset.var] = DEFAULTS[el.dataset.var];
    });
    saveVars(vars);
    updateTokens();
  });

  // Run once DOM has rendered
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', tokenizeCodeBlocks);
  } else {
    tokenizeCodeBlocks();
  }

  // Expose to copy.js so it grabs resolved text
  window.__pcVars = vars;
})();
