import { mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { toRoute } from './docs-manifest.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const contentRoot = path.resolve(projectRoot, 'src', 'content', 'docs');
const outputRoot = path.resolve(projectRoot, 'public', 'page-markdown');

async function main() {
  await rm(outputRoot, { force: true, recursive: true });

  const sourceFiles = await collectContentFiles(contentRoot);

  for (const sourceFile of sourceFiles) {
    const relativePath = normalizePath(path.relative(contentRoot, sourceFile));
    const raw = await readFile(sourceFile, 'utf8');
    const markdown = transformToMarkdown(raw);
    const assetPath = path.resolve(outputRoot, toAssetPath(relativePath));

    await mkdir(path.dirname(assetPath), { recursive: true });
    await writeFile(assetPath, markdown, 'utf8');
  }

  console.log(`Generated Markdown copy artifacts for ${sourceFiles.length} documentation pages.`);
}

async function collectContentFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const results = [];

  for (const entry of entries) {
    const entryPath = path.resolve(directory, entry.name);
    if (entry.isDirectory()) {
      results.push(...(await collectContentFiles(entryPath)));
      continue;
    }

    if (/\.(md|mdx)$/i.test(entry.name)) {
      results.push(entryPath);
    }
  }

  return results.sort();
}

function transformToMarkdown(content) {
  const { title, body } = splitFrontmatter(content);
  let markdown = body;

  markdown = markdown.replace(/^import\s+.+?;\s*$/gm, '');
  markdown = markdown.replace(/<div className="hero-note">\s*([\s\S]*?)\s*<\/div>/g, '$1');
  markdown = markdown.replace(/<div className="site-link-list">\s*([\s\S]*?)\s*<\/div>/g, '$1');
  markdown = markdown.replace(/^[ \t]*<CardGrid[^>]*>\s*$/gm, '');
  markdown = markdown.replace(/^[ \t]*<\/CardGrid>\s*$/gm, '');
  markdown = markdown.replace(
    /^[ \t]*<Card\s+title="([^"]+)"\s+icon="([^"]*)"\s+href="([^"]+)">\s*([\s\S]*?)\s*<\/Card>/gm,
    (_match, cardTitle, _icon, href, description) => {
      const normalizedDescription = description.trim().replace(/\s+/g, ' ');
      return `- [${cardTitle}](${href})${normalizedDescription ? `: ${normalizedDescription}` : ''}`;
    },
  );

  markdown = markdown.trim();

  if (title && !markdown.startsWith('# ')) {
    markdown = `# ${title}\n\n${markdown}`;
  }

  return `${markdown.replace(/\n{3,}/g, '\n\n').trim()}\n`;
}

function splitFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n*/);
  if (!match) {
    return { title: null, body: content };
  }

  const frontmatter = match[1];
  const titleMatch = frontmatter.match(/^title:\s*(.+)$/m);

  return {
    title: titleMatch ? parseScalar(titleMatch[1].trim()) : null,
    body: content.slice(match[0].length),
  };
}

function parseScalar(value) {
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    try {
      return JSON.parse(value);
    } catch {
      return value.slice(1, -1);
    }
  }

  return value;
}

function toAssetPath(relativePath) {
  const route = toRoute(relativePath);
  const routePath = route === '/' ? 'index' : route.replace(/^\//, '').replace(/\/$/, '');
  return `${routePath}.md`;
}

function normalizePath(value) {
  return value.replace(/\\/g, '/');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
