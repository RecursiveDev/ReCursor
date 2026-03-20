import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

const site = process.env.DOCS_SITE_URL ?? 'https://recursivedev.github.io';
const base = process.env.DOCS_BASE ?? '/';

export default defineConfig({
  site,
  base,
  output: 'static',
  integrations: [
    starlight({
      title: 'ReCursor Docs',
      description:
        'Bridge-first documentation for the ReCursor mobile companion UI and bridge architecture.',
      logo: {
        light: './src/assets/recursor-logo-light.svg',
        dark: './src/assets/recursor-logo-dark.svg',
        replacesTitle: false,
      },
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/RecursiveDev/ReCursor',
        },
      ],
      editLink: {
        baseUrl: 'https://github.com/RecursiveDev/ReCursor/edit/main/docs-site/src/content/docs/',
      },
      customCss: ['./src/styles/custom.css'],
      components: {
        Head: './src/components/Head.astro',
        EditLink: './src/components/EditLink.astro',
        Footer: './src/components/Footer.astro',
        PageTitle: './src/components/PageTitle.astro',
        SiteTitle: './src/components/SiteTitle.astro',
        ThemeSelect: './src/components/ThemeSelect.astro',
      },
      sidebar: [
        { label: 'Home', link: '/' },
        {
          label: 'Getting started',
          autogenerate: { directory: 'getting-started' },
        },
        {
          label: 'Architecture',
          autogenerate: { directory: 'architecture' },
        },
        {
          label: 'Integrations',
          autogenerate: { directory: 'integrations' },
        },
        {
          label: 'Operations',
          autogenerate: { directory: 'operations' },
        },
        {
          label: 'Reference',
          autogenerate: { directory: 'reference' },
        },
        {
          label: 'Wireframes',
          autogenerate: { directory: 'wireframes' },
        },
        {
          label: 'Research',
          autogenerate: { directory: 'research' },
        },
        {
          label: 'Legal',
          autogenerate: { directory: 'legal' },
        },
      ],
    }),
  ],
});
