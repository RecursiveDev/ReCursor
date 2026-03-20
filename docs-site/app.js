// ===== Page Registry =====
const pages = [
  { id: 'overview', title: 'Overview', section: 'Getting Started' },
  { id: 'architecture', title: 'Architecture', section: 'Getting Started' },
  { id: 'quickstart', title: 'Quickstart', section: 'Getting Started' },
  { id: 'bridge-protocol', title: 'Bridge Protocol', section: 'Core Concepts' },
  { id: 'data-flow', title: 'Data Flow', section: 'Core Concepts' },
  { id: 'offline', title: 'Offline Architecture', section: 'Core Concepts' },
  { id: 'hooks', title: 'Claude Code Hooks', section: 'Integration' },
  { id: 'agent-sdk', title: 'Agent SDK', section: 'Integration' },
  { id: 'ui-patterns', title: 'OpenCode UI Patterns', section: 'Integration' },
  { id: 'security', title: 'Security Architecture', section: 'Security' },
  { id: 'roadmap', title: 'Roadmap', section: 'Development' },
  { id: 'tech-stack', title: 'Tech Stack', section: 'Development' },
];

// ===== Page Cache & State =====
const pageCache = {};   // id -> HTML string
const searchIndex = {}; // id -> lowercase text for search
let currentPageIndex = 0;

// ===== Dynamic Page Loading =====
async function fetchPage(pageId) {
  if (pageCache[pageId]) return pageCache[pageId];

  try {
    const resp = await fetch(`pages/${pageId}.html`);
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    const html = await resp.text();
    pageCache[pageId] = html;
    return html;
  } catch (err) {
    console.error(`Failed to load page: ${pageId}`, err);
    return `<article class="page"><div class="page-header"><h1>Page not found</h1><p class="page-subtitle">Could not load "${pageId}".</p></div></article>`;
  }
}

async function navigateTo(pageId) {
  const index = pages.findIndex(p => p.id === pageId);
  if (index === -1) return;
  currentPageIndex = index;

  const container = document.getElementById('pageContainer');

  // Show loading state briefly
  container.innerHTML = '<div class="page-loading"><div class="loading-spinner"></div></div>';

  const html = await fetchPage(pageId);
  container.innerHTML = html;

  // Build search index for this page if not yet done
  if (!searchIndex[pageId]) {
    searchIndex[pageId] = container.textContent.toLowerCase();
  }

  // Attach copy handlers on newly-inserted code blocks
  attachCopyHandlers(container);

  // Inject "Copy page" button into the page header
  injectCopyPageButton(container);

  // Update nav active state
  document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.toggle('active', item.dataset.page === pageId);
  });

  updateFooterNav();
  window.scrollTo({ top: 0 });
  closeSidebar();
}

// ===== Pre-fetch all pages for search index =====
async function buildSearchIndex() {
  await Promise.all(pages.map(async (p) => {
    const html = await fetchPage(p.id);
    // Parse the text from html for search
    const tmp = document.createElement('div');
    tmp.innerHTML = html;
    searchIndex[p.id] = tmp.textContent.toLowerCase();
  }));
}

// ===== Footer Navigation =====
function updateFooterNav() {
  const prevBtn = document.getElementById('footerPrev');
  const nextBtn = document.getElementById('footerNext');
  const prevTitle = document.getElementById('prevTitle');
  const nextTitle = document.getElementById('nextTitle');

  if (currentPageIndex > 0) {
    const prev = pages[currentPageIndex - 1];
    prevBtn.style.display = 'flex';
    prevBtn.href = '#' + prev.id;
    prevTitle.textContent = prev.title;
  } else {
    prevBtn.style.display = 'none';
  }

  if (currentPageIndex < pages.length - 1) {
    const next = pages[currentPageIndex + 1];
    nextBtn.style.display = 'flex';
    nextBtn.href = '#' + next.id;
    nextTitle.textContent = next.title;
  } else {
    nextBtn.style.display = 'none';
  }
}

// ===== Copy Handlers (Code + Markdown) =====
function attachCopyHandlers(root) {
  root.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const mode = btn.dataset.mode; // "code" or "markdown"
      const block = btn.closest('.code-block');
      const codeEl = block.querySelector('code');
      const rawCode = codeEl.textContent;

      let textToCopy;
      if (mode === 'markdown') {
        const lang = block.dataset.lang || '';
        // data-md-lang overrides the fence language (e.g. empty for plain text)
        const mdLang = block.hasAttribute('data-md-lang') ? block.dataset.mdLang : lang;
        textToCopy = '```' + mdLang + '\n' + rawCode + '\n```';
      } else {
        textToCopy = rawCode;
      }

      writeClipboard(textToCopy, btn);
    });
  });
}

function writeClipboard(text, btn) {
  navigator.clipboard.writeText(text).then(() => {
    flashCopied(btn);
  }).catch(() => {
    // Fallback for non-HTTPS / older browsers
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
    flashCopied(btn);
  });
}

function flashCopied(btn) {
  const original = btn.textContent;
  btn.textContent = 'Copied!';
  btn.classList.add('copied');
  setTimeout(() => {
    btn.textContent = original;
    btn.classList.remove('copied');
  }, 2000);
}

// ===== Copy Page Button =====
function injectCopyPageButton(container) {
  const header = container.querySelector('.page-header');
  if (!header) return;

  // Don't double-inject
  if (header.querySelector('.copy-page-btn')) return;

  const btn = document.createElement('button');
  btn.className = 'copy-page-btn';
  btn.innerHTML = `<svg width="14" height="14" viewBox="0 0 16 16" fill="none"><rect x="5" y="1" width="9" height="11" rx="1.5" stroke="currentColor" stroke-width="1.4"/><rect x="2" y="4" width="9" height="11" rx="1.5" stroke="currentColor" stroke-width="1.4" fill="var(--bg-secondary)"/></svg><span>Copy page</span>`;
  btn.addEventListener('click', () => {
    const article = container.querySelector('article.page');
    if (!article) return;
    const md = pageToMarkdown(article);
    writeClipboard(md, btn.querySelector('span'));
  });

  header.appendChild(btn);
}

// ===== HTML-to-Markdown Converter =====
function pageToMarkdown(article) {
  const lines = [];
  const children = article.children;

  for (const node of children) {
    convertNode(node, lines);
  }

  return lines.join('\n').replace(/\n{3,}/g, '\n\n').trim() + '\n';
}

function convertNode(el, lines) {
  const tag = el.tagName;

  // Skip non-content elements
  if (el.classList.contains('copy-page-btn')) return;
  if (el.classList.contains('copy-actions')) return;

  // Page header block
  if (el.classList.contains('page-header')) {
    const h1 = el.querySelector('h1');
    const subtitle = el.querySelector('.page-subtitle');
    if (h1) lines.push('# ' + h1.textContent.trim(), '');
    if (subtitle) lines.push('> ' + subtitle.textContent.trim(), '');
    return;
  }

  // Headings
  if (/^H[1-6]$/.test(tag)) {
    const level = parseInt(tag[1]);
    lines.push('', '#'.repeat(level) + ' ' + el.textContent.trim(), '');
    return;
  }

  // Callouts
  if (el.classList.contains('callout')) {
    const content = el.querySelector('.callout-content');
    if (content) {
      lines.push('', '> ' + inlineText(content), '');
    }
    return;
  }

  // Code blocks
  if (el.classList.contains('code-block')) {
    const code = el.querySelector('code');
    const lang = el.dataset.lang || '';
    const mdLang = el.hasAttribute('data-md-lang') ? el.dataset.mdLang : lang;
    lines.push('', '```' + mdLang);
    lines.push(code.textContent);
    lines.push('```', '');
    return;
  }

  // Diagrams
  if (el.classList.contains('diagram-container')) {
    const pre = el.querySelector('pre');
    if (pre) {
      lines.push('', '```');
      lines.push(pre.textContent);
      lines.push('```', '');
    }
    return;
  }

  // Tables
  if (tag === 'TABLE') {
    lines.push('');
    const rows = el.querySelectorAll('tr');
    rows.forEach((row, i) => {
      const cells = row.querySelectorAll('th, td');
      const cellTexts = Array.from(cells).map(c => inlineText(c));
      lines.push('| ' + cellTexts.join(' | ') + ' |');
      if (i === 0) {
        lines.push('| ' + cellTexts.map(() => '---').join(' | ') + ' |');
      }
    });
    lines.push('');
    return;
  }

  // Paragraphs
  if (tag === 'P') {
    lines.push(inlineText(el), '');
    return;
  }

  // Unordered lists
  if (tag === 'UL') {
    const items = el.querySelectorAll(':scope > li');
    items.forEach(li => {
      lines.push('- ' + inlineText(li));
    });
    lines.push('');
    return;
  }

  // Ordered lists
  if (tag === 'OL') {
    const items = el.querySelectorAll(':scope > li');
    items.forEach((li, i) => {
      lines.push((i + 1) + '. ' + inlineText(li));
    });
    lines.push('');
    return;
  }

  // Feature grid
  if (el.classList.contains('feature-grid')) {
    const cards = el.querySelectorAll('.feature-card');
    cards.forEach(card => {
      const h3 = card.querySelector('h3');
      const p = card.querySelector('p');
      if (h3) lines.push('### ' + h3.textContent.trim());
      if (p) lines.push(p.textContent.trim(), '');
    });
    return;
  }

  // Two-column layout
  if (el.classList.contains('two-col')) {
    for (const child of el.children) {
      for (const inner of child.children) {
        convertNode(inner, lines);
      }
    }
    return;
  }

  // Phase cards
  if (el.classList.contains('phase-card')) {
    const header = el.querySelector('.phase-header');
    if (header) lines.push('', '**' + header.textContent.trim() + '**');
    const ul = el.querySelector('ul');
    if (ul) convertNode(ul, lines);
    return;
  }

  // Accordion / details
  if (tag === 'DETAILS') {
    const summary = el.querySelector('summary');
    const content = el.querySelector('.accordion-content');
    if (summary) lines.push('', '**' + summary.textContent.trim() + '**');
    if (content) {
      for (const child of content.children) {
        convertNode(child, lines);
      }
    }
    return;
  }

  // Generic container — recurse (div, section, nav, etc.)
  if (el.children && el.children.length > 0) {
    for (const child of el.children) {
      convertNode(child, lines);
    }
    return;
  }
}

function inlineText(el) {
  let result = '';
  for (const node of el.childNodes) {
    if (node.nodeType === Node.TEXT_NODE) {
      result += node.textContent;
    } else if (node.nodeType === Node.ELEMENT_NODE) {
      const tag = node.tagName;
      // Skip copy buttons
      if (node.classList.contains('copy-actions') || node.classList.contains('copy-btn') || node.classList.contains('copy-page-btn')) continue;

      if (tag === 'STRONG' || tag === 'B') {
        result += '**' + inlineText(node) + '**';
      } else if (tag === 'EM' || tag === 'I') {
        result += '*' + inlineText(node) + '*';
      } else if (tag === 'CODE') {
        result += '`' + node.textContent + '`';
      } else if (tag === 'A') {
        const href = node.getAttribute('href') || '';
        result += '[' + inlineText(node) + '](' + href + ')';
      } else if (tag === 'SPAN' && node.classList.contains('badge')) {
        result += node.textContent.trim();
      } else if (tag === 'SPAN' && node.classList.contains('direction')) {
        result += ' ' + node.textContent.trim();
      } else {
        result += inlineText(node);
      }
    }
  }
  return result.replace(/\s+/g, ' ').trim();
}

// ===== Event Listeners =====

// Nav items
document.querySelectorAll('.nav-item').forEach(item => {
  item.addEventListener('click', (e) => {
    e.preventDefault();
    navigateTo(item.dataset.page);
    history.pushState(null, '', '#' + item.dataset.page);
  });
});

// Footer nav
document.getElementById('footerPrev').addEventListener('click', (e) => {
  e.preventDefault();
  if (currentPageIndex > 0) {
    const prev = pages[currentPageIndex - 1];
    navigateTo(prev.id);
    history.pushState(null, '', '#' + prev.id);
  }
});

document.getElementById('footerNext').addEventListener('click', (e) => {
  e.preventDefault();
  if (currentPageIndex < pages.length - 1) {
    const next = pages[currentPageIndex + 1];
    navigateTo(next.id);
    history.pushState(null, '', '#' + next.id);
  }
});

// In-page anchor links (delegated)
document.addEventListener('click', (e) => {
  const link = e.target.closest('a[href^="#"]');
  if (link && !link.classList.contains('nav-item') && !link.classList.contains('footer-prev') && !link.classList.contains('footer-next')) {
    const target = link.getAttribute('href').slice(1);
    const page = pages.find(p => p.id === target);
    if (page) {
      e.preventDefault();
      navigateTo(target);
      history.pushState(null, '', '#' + target);
    }
  }
});

// Hash change (browser back/forward)
window.addEventListener('hashchange', () => {
  const hash = window.location.hash.slice(1) || 'overview';
  navigateTo(hash);
});

// ===== Mobile Sidebar =====
const sidebarToggle = document.getElementById('sidebarToggle');
const sidebar = document.getElementById('sidebar');
const sidebarOverlay = document.getElementById('sidebarOverlay');

function openSidebar() {
  sidebar.classList.add('open');
  sidebarOverlay.classList.add('visible');
}

function closeSidebar() {
  sidebar.classList.remove('open');
  sidebarOverlay.classList.remove('visible');
}

sidebarToggle.addEventListener('click', () => {
  sidebar.classList.contains('open') ? closeSidebar() : openSidebar();
});

sidebarOverlay.addEventListener('click', closeSidebar);

// ===== Search =====
const searchBar = document.getElementById('searchBar');
const searchModal = document.getElementById('searchModal');
const searchModalInput = document.getElementById('searchModalInput');
const searchResults = document.getElementById('searchResults');

function openSearch() {
  searchModal.style.display = 'flex';
  searchModalInput.value = '';
  searchModalInput.focus();
  renderSearchResults('');
}

function closeSearch() {
  searchModal.style.display = 'none';
}

function renderSearchResults(query) {
  if (!query.trim()) {
    searchResults.innerHTML = pages.map(p =>
      `<a class="search-result-item" data-page="${p.id}" href="#${p.id}">
        <div class="search-result-section">${p.section}</div>
        <div class="search-result-title">${p.title}</div>
      </a>`
    ).join('');
    return;
  }

  const q = query.toLowerCase().trim();
  const results = pages.filter(p =>
    p.title.toLowerCase().includes(q) || (searchIndex[p.id] && searchIndex[p.id].includes(q))
  );

  if (results.length === 0) {
    searchResults.innerHTML = '<div class="search-no-results">No results found</div>';
    return;
  }

  searchResults.innerHTML = results.map(p =>
    `<a class="search-result-item" data-page="${p.id}" href="#${p.id}">
      <div class="search-result-section">${p.section}</div>
      <div class="search-result-title">${p.title}</div>
    </a>`
  ).join('');
}

searchBar.addEventListener('click', openSearch);

searchModal.querySelector('.search-modal-overlay').addEventListener('click', closeSearch);

searchModalInput.addEventListener('input', (e) => {
  renderSearchResults(e.target.value);
});

searchResults.addEventListener('click', (e) => {
  const item = e.target.closest('.search-result-item');
  if (item) {
    e.preventDefault();
    const pageId = item.dataset.page;
    closeSearch();
    navigateTo(pageId);
    history.pushState(null, '', '#' + pageId);
  }
});

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
  // Ctrl+K / Cmd+K to toggle search
  if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
    e.preventDefault();
    searchModal.style.display === 'flex' ? closeSearch() : openSearch();
  }

  // Escape to close search
  if (e.key === 'Escape' && searchModal.style.display === 'flex') {
    closeSearch();
  }

  // Arrow nav in search results
  if (searchModal.style.display === 'flex') {
    const items = searchResults.querySelectorAll('.search-result-item');
    const active = searchResults.querySelector('.search-result-item.active');
    let idx = Array.from(items).indexOf(active);

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (active) active.classList.remove('active');
      idx = (idx + 1) % items.length;
      items[idx].classList.add('active');
      items[idx].scrollIntoView({ block: 'nearest' });
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (active) active.classList.remove('active');
      idx = idx <= 0 ? items.length - 1 : idx - 1;
      items[idx].classList.add('active');
      items[idx].scrollIntoView({ block: 'nearest' });
    } else if (e.key === 'Enter') {
      if (active) {
        e.preventDefault();
        const pageId = active.dataset.page;
        closeSearch();
        navigateTo(pageId);
        history.pushState(null, '', '#' + pageId);
      }
    }
  }
});

// ===== Init =====
(async () => {
  const initialHash = window.location.hash.slice(1) || 'overview';
  await navigateTo(initialHash);
  // Pre-fetch remaining pages in the background for search
  buildSearchIndex();
})();
