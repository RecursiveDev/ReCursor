import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { DOCS_MANIFEST, toRoute } from './docs-manifest.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const sourceRoot = path.resolve(projectRoot, '..', 'docs');
const contentRoot = path.resolve(projectRoot, 'src', 'content', 'docs');

const SOURCE_TO_OUTPUT = new Map(
  DOCS_MANIFEST.map((entry) => [normalizePath(entry.source), normalizePath(entry.output)]),
);

async function main() {
  await cleanGeneratedOutputs();

  for (const entry of DOCS_MANIFEST) {
    const sourcePath = path.resolve(sourceRoot, entry.source);
    const destinationPath = path.resolve(contentRoot, entry.output);
    const raw = await readFile(sourcePath, 'utf8');
    const metadata = extractMetadata(raw, entry);
    const body = rewriteLinks(stripLeadingHeading(raw), entry.source);
    const frontmatter = buildFrontmatter(metadata, entry);

    await mkdir(path.dirname(destinationPath), { recursive: true });
    await writeFile(destinationPath, `${frontmatter}\n${body.trim()}\n`, 'utf8');
  }

  console.log(`Generated ${DOCS_MANIFEST.length} documentation pages.`);
}

async function cleanGeneratedOutputs() {
  for (const entry of DOCS_MANIFEST) {
    const destinationPath = path.resolve(contentRoot, entry.output);
    await rm(destinationPath, { force: true });
  }
}

function extractMetadata(content, entry) {
  const title = extractTitle(content) ?? humanizeFilename(path.basename(entry.output, path.extname(entry.output)));
  const description = extractDescription(content) ?? `${title} for the ReCursor project.`;

  return {
    title,
    description,
  };
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

function rewriteLinks(content, sourcePath) {
  return content.replace(/(!?\[[^\]]*\]\()([^\s)]+)(\))/g, (_match, prefix, target, suffix) => {
    const resolved = rewriteTarget(target, sourcePath);
    return `${prefix}${resolved}${suffix}`;
  });
}

function rewriteTarget(target, sourcePath) {
  if (
    target.startsWith('#') ||
    target.startsWith('http://') ||
    target.startsWith('https://') ||
    target.startsWith('mailto:') ||
    target.startsWith('tel:') ||
    target.startsWith('/')
  ) {
    return target;
  }

  const [rawPath, hash = ''] = target.split('#');
  if (!rawPath) {
    return target;
  }

  const normalizedSource = normalizePath(sourcePath);
  const sourceDirectory = path.posix.dirname(normalizedSource);
  const candidate = resolveSourceTarget(sourceDirectory, rawPath);
  if (!candidate) {
    return target;
  }

  const outputPath = SOURCE_TO_OUTPUT.get(candidate);
  if (!outputPath) {
    return target;
  }

  const anchor = hash ? `#${hash}` : '';
  return `${toRoute(outputPath)}${anchor}`;
}

function resolveSourceTarget(sourceDirectory, rawPath) {
  const normalizedTarget = normalizePath(rawPath);
  const directCandidate = path.posix.normalize(path.posix.join(sourceDirectory, normalizedTarget));
  const variations = new Set([directCandidate]);

  if (!path.posix.extname(directCandidate)) {
    variations.add(`${directCandidate}.md`);
    variations.add(`${directCandidate}.mdx`);
    variations.add(path.posix.join(directCandidate, 'README.md'));
    variations.add(path.posix.join(directCandidate, 'index.md'));
  }

  for (const candidate of variations) {
    if (SOURCE_TO_OUTPUT.has(candidate)) {
      return candidate;
    }
  }

  return null;
}

function buildFrontmatter(metadata, entry) {
  const lines = ['---'];
  lines.push(`title: ${yamlString(metadata.title)}`);
  lines.push(`description: ${yamlString(metadata.description)}`);
  lines.push(`editUrl: ${yamlString(buildEditUrl(entry.source))}`);
  lines.push('sidebar:');
  lines.push(`  order: ${entry.order}`);
  if (entry.label) {
    lines.push(`  label: ${yamlString(entry.label)}`);
  }
  lines.push('---');
  return lines.join('\n');
}

function buildEditUrl(sourcePath) {
  return `https://github.com/RecursiveDev/ReCursor/edit/main/docs/${normalizePath(sourcePath)}`;
}

function yamlString(value) {
  return JSON.stringify(value);
}

function normalizePath(value) {
  return value.replace(/\\/g, '/');
}

function humanizeFilename(filename) {
  return filename
    .replace(/^\d+-/, '')
    .replace(/[-_]+/g, ' ')
    .replace(/\b\w/g, (character) => character.toUpperCase());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
