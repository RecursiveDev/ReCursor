/**
 * Generate LLMS AI artifact files with base-path aware URLs.
 *
 * This script generates llms.txt and llms-full.txt files that contain
 * documentation navigation and full content for AI workflows.
 *
 * Base path handling:
 * - Uses DOCS_BASE environment variable (e.g., '/ReCursor/')
 * - Falls back to '/' if not set
 * - Generated URLs are properly prefixed for GitHub Pages project sites
 *
 * Source:
 * - Reads directly from docs-site/src/content/docs/ (canonical source)
 */

import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { SECTION_META, SECTION_ORDER, SITE_DESCRIPTION, SITE_TITLE, toRoute } from './docs-manifest.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const contentRoot = path.resolve(projectRoot, 'src', 'content', 'docs');
const publicRoot = path.resolve(projectRoot, 'public');

// Get base path from environment or default to '/'
// Note: For production builds, set DOCS_BASE=/ReCursor/
const BASE_PATH = (() => {
  const envBase = process.env.DOCS_BASE ?? '/';
  // Handle Windows paths that might get garbled
  if (envBase.includes(':')) return '/';
  if (!envBase.startsWith('/')) return '/' + envBase;
  return envBase;
})();

async function main() {
  const docs = await collectDocs();

  await mkdir(publicRoot, { recursive: true });
  await writeFile(path.resolve(publicRoot, 'llms.txt'), buildLlmsIndex(docs), 'utf8');
  await writeFile(path.resolve(publicRoot, 'llms-full.txt'), buildLlmsFull(docs), 'utf8');

  console.log(`Generated AI artifacts for ${docs.length} documentation pages.`);
  console.log(`Base path: ${BASE_PATH}`);
}

async function collectDocs() {
  const docs = [];

  for (const sectionKey of SECTION_ORDER) {
    const sectionDir = path.resolve(contentRoot, sectionKey);
    const files = await collectMdFiles(sectionDir);

    for (const file of files) {
      const relativePath = path.relative(contentRoot, file);
      const raw = await readFile(file, 'utf8');
      const { frontmatter, body } = parseFrontmatter(raw);

      // Skip index files for llms (they're navigation only)
      if (relativePath.endsWith('index.mdx') || relativePath.endsWith('index.md')) {
        continue;
      }

      const route = toRoute(relativePath, BASE_PATH);
      const title = frontmatter.title ?? extractTitle(body) ?? humanizePath(relativePath);
      const description = frontmatter.description ?? extractDescription(body) ?? `${title} for the ReCursor project.`;

      docs.push({
        section: sectionKey,
        relativePath,
        route,
        title,
        description,
        content: stripFrontmatter(raw).trim(),
      });
    }
  }

  return docs.sort((a, b) => {
    if (a.section !== b.section) {
      return SECTION_ORDER.indexOf(a.section) - SECTION_ORDER.indexOf(b.section);
    }
    return a.relativePath.localeCompare(b.relativePath);
  });
}

async function collectMdFiles(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const entryPath = path.resolve(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await collectMdFiles(entryPath)));
      continue;
    }

    if (/\.(md|mdx)$/i.test(entry.name)) {
      files.push(entryPath);
    }
  }

  return files;
}

function parseFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n*/);
  if (!match) {
    return { frontmatter: {}, body: content };
  }

  const frontmatter = {};
  const frontmatterText = match[1];

  for (const line of frontmatterText.split('\n')) {
    const colonIndex = line.indexOf(':');
    if (colonIndex === -1) continue;

    const key = line.slice(0, colonIndex).trim();
    let value = line.slice(colonIndex + 1).trim();

    // Parse YAML-like values
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.slice(1, -1);
    } else if (value.startsWith("'") && value.endsWith("'")) {
      value = value.slice(1, -1);
    } else if (value === 'true') {
      value = true;
    } else if (value === 'false') {
      value = false;
    } else if (/^\d+$/.test(value)) {
      value = parseInt(value, 10);
    }

    frontmatter[key] = value;
  }

  return { frontmatter, body: content.slice(match[0].length) };
}

function stripFrontmatter(content) {
  return content.replace(/^---[\s\S]*?---\r?\n*/, '').trim();
}

function extractTitle(content) {
  const match = content.match(/^#\s+(.+)$/m);
  return match?.[1]?.trim();
}

function extractDescription(content) {
  const quoteBlock = content.match(/^>\s+(.+(?:\n>\s+.+)*)/m);
  if (quoteBlock?.[1]) {
    return quoteBlock[1]
      .split('\n')
      .map((line) => line.replace(/^>\s?/, '').trim())
      .join(' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  // Get first paragraph that isn't a heading or code block
  const paragraphs = content
    .split(/\n\s*\n/g)
    .map((block) => block.trim())
    .filter(Boolean)
    .filter((block) => !block.startsWith('#'))
    .filter((block) => !block.startsWith('```'))
    .filter((block) => !block.startsWith('|'))
    .filter((block) => !block.startsWith('---'));

  return paragraphs[0]?.replace(/\s+/g, ' ').trim();
}

function humanizePath(relativePath) {
  return relativePath
    .replace(/\.(md|mdx)$/i, '')
    .replace(/[-_/]+/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function buildLlmsIndex(docs) {
  const lines = [
    `# ${SITE_TITLE}`,
    `> ${SITE_DESCRIPTION}`,
    '',
    'Canonical source documents live in `docs-site/src/content/docs/` in the repository.',
    '',
    '## AI Artifacts',
    '- [llms.txt](./llms.txt): Compact machine-readable navigation for the published documentation.',
    '- [llms-full.txt](./llms-full.txt): Concatenated long-form documentation context for AI workflows.',
    '',
  ];

  for (const sectionKey of SECTION_ORDER) {
    const sectionDocs = docs.filter((doc) => doc.section === sectionKey);
    if (sectionDocs.length === 0) {
      continue;
    }

    lines.push(`## ${SECTION_META[sectionKey].title}`);
    lines.push(SECTION_META[sectionKey].description);
    lines.push('');

    for (const doc of sectionDocs) {
      lines.push(`- [${doc.title}](${doc.route}): ${doc.description}`);
    }

    lines.push('');
  }

  return `${lines.join('\n').trim()}\n`;
}

function buildLlmsFull(docs) {
  const lines = [
    `# ${SITE_TITLE} — Full AI Context`,
    `> ${SITE_DESCRIPTION}`,
    '',
    'Canonical source documents live in `docs-site/src/content/docs/` in the repository.',
    'This artifact concatenates the published documentation corpus for AI-assisted workflows.',
    '',
  ];

  for (const doc of docs) {
    lines.push('---');
    lines.push(`Route: ${doc.route}`);
    lines.push(`Source: docs-site/src/content/docs/${doc.relativePath}`);
    lines.push(`Title: ${doc.title}`);
    lines.push(`Description: ${doc.description}`);
    lines.push('');
    lines.push(doc.content);
    lines.push('');
  }

  return `${lines.join('\n').trim()}\n`;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});