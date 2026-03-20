# ReCursor docs-site

This folder contains the Astro Starlight documentation site for ReCursor.

## How it works

- Canonical Markdown source lives in `C:/Repository/ReCursor/docs/`.
- `npm run generate` copies that source into `src/content/docs/`, rewrites internal links to the published information architecture, and generates `public/llms.txt` plus `public/llms-full.txt`.
- Section landing pages in `src/content/docs/` provide the curated Starlight navigation layer.

## Commands

```bash
npm install
npm run dev
npm run check
npm run build
```

## Editing guidance

- Update canonical content in `C:/Repository/ReCursor/docs/` whenever possible.
- Update `scripts/docs-manifest.mjs` if a source document is added, renamed, or moved in the published site.
- Keep claims about Claude Code aligned with `C:/Repository/ReCursor/AGENTS.md`.
