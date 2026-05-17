// Add copy-to-clipboard buttons to every <pre><code> block.
(function () {
  function addButtons() {
    document.querySelectorAll('pre').forEach((pre) => {
      if (pre.querySelector('.copy-btn')) return;
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'copy-btn';
      btn.textContent = 'copy';
      btn.setAttribute('aria-label', 'Copy snippet');
      btn.addEventListener('click', async () => {
        // .innerText preserves var-token replacements
        const code = pre.querySelector('code');
        const text = code ? code.innerText : pre.innerText;
        try {
          await navigator.clipboard.writeText(text);
          btn.textContent = 'copied!';
          btn.classList.add('copied');
          setTimeout(() => { btn.textContent = 'copy'; btn.classList.remove('copied'); }, 1200);
        } catch {
          btn.textContent = 'failed';
          setTimeout(() => { btn.textContent = 'copy'; }, 1200);
        }
      });
      pre.appendChild(btn);
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', addButtons);
  else addButtons();
})();
