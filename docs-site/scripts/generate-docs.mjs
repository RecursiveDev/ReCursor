/**
 * Documentation generation script
 *
 * Docs are now authored directly in docs-site/src/content/docs/
 * This script is a no-op since the content is already in the canonical location.
 *
 * Previously, this script copied from a separate docs/ directory.
 * The docs/ directory has been merged into docs-site/src/content/docs/
 */

async function main() {
  console.log('Docs are authored directly in src/content/docs/. Skipping generation.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});