/**
 * Generate LLMS AI artifact files with base-path aware URLs.
 * 
 * This script generates llms.txt and llms-full.txt files that contain
 * documentation navigation and full content for AI workflows.
 * 
 * Base path handling:
 * - Uses DOCS_BASE environment variable (e.g., '/ReCursor/')
 * - Falls back to '/'' if not set
 * - Generated URLs are properly prefixed for GitHub Pages project sites
 */

import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { DOCS_MANIFEST, SECTION_META, SECTION_ORDER, SITE_DESCRIPTION, SITE_TITLE, toRoute } from './docs-manifest.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const sourceRoot = path.resolve(projectRoot, '..', 'docs');
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
  const docs = [];

  for (const entry of DOCS_MANIFEST) {
    const sourcePath = path.resolve(sourceRoot, entry.source);
    const raw = await readFile(sourcePath, 'utf8');
    const title = extractTitle(raw) ?? entry.label ?? path.basename(entry.source, '.md');
    const description = extractDescription(raw) ?? `${title} for the ReCursor project.`;

    docs.push({
      ...entry,
      title,
      description,
      route: toRoute(entry.output, BASE_PATH),
      content: stripLeadingHeading(raw).trim(),
    });
  }

  await mkdir(publicRoot, { recursive: true });
  await writeFile(path.resolve(publicRoot, 'llms.txt'), buildLlmsIndex(docs), 'utf8');
  await writeFile(path.resolve(publicRoot, 'llms-full.txt'), buildLlmsFull(docs), 'utf8');

  console.log(`Generated AI artifacts for ${docs.length} documentation pages.`);
  console.log(`Base path: ${BASE_PATH}`);
}

function buildLlmsIndex(docs) {
  const lines = [
    `# ${SITE_TITLE}`,
    `> ${SITE_DESCRIPTION}`,
    '',
    'Canonical source documents live in `/docs` in the repository. This published site is generated from that source-of-truth corpus.',
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
    'Canonical source documents live in `/docs` in the repository. This artifact concatenates the published documentation corpus for AI-assisted workflows.',
    '',
  ];

  for (const doc of docs) {
    lines.push('---');
    lines.push(`Route: ${doc.route}`);
    lines.push(`Source: /docs/${doc.source}`);
    lines.push(`Title: ${doc.title}`);
    lines.push(`Description: ${doc.description}`);
    lines.push('');
    lines.push(doc.content);
    lines.push('');
  }

  return `${lines.join('\n').trim()}\n`;
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

function stripLeadingHeading(content) {
  return content.replace(/^#\s+.+\n+/, '').trim();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
