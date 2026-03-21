export const SITE_TITLE = 'ReCursor Docs';
export const SITE_DESCRIPTION =
  'Mobile-first companion UI for AI coding workflows, documented as a bridge-first Astro Starlight site.';

export const SECTION_ORDER = [
  'getting-started',
  'architecture',
  'integrations',
  'operations',
  'reference',
  'legal',
];

export const SECTION_META = {
  'getting-started': {
    title: 'Getting started',
    description: 'Documentation entry points and publishing guidance.',
  },
  architecture: {
    title: 'Architecture',
    description: 'System structure, data flow, and design constraints.',
  },
  integrations: {
    title: 'Integrations',
    description: 'Supported Claude Code and OpenCode integration paths.',
  },
  operations: {
    title: 'Operations',
    description: 'Security, notifications, CI/CD, and testing guidance.',
  },
  reference: {
    title: 'Reference',
    description: 'Protocol, API, error handling, and type contract references.',
  },
  legal: {
    title: 'Legal',
    description: 'Policy and terms documents for the project.',
  },
};

export const DOCS_MANIFEST = [
  {
    source: 'README.md',
    output: 'getting-started/documentation-index.md',
    section: 'getting-started',
    order: 10,
    label: 'Documentation index',
  },
  {
    source: 'architecture/overview.md',
    output: 'architecture/system-overview.md',
    section: 'architecture',
    order: 10,
    label: 'System overview',
  },
  {
    source: 'architecture/data-flow.md',
    output: 'architecture/data-flow.md',
    section: 'architecture',
    order: 20,
    label: 'Data flow',
  },
  {
    source: 'project-structure.md',
    output: 'architecture/project-structure.md',
    section: 'architecture',
    order: 30,
    label: 'Project structure',
  },
  {
    source: 'data-models.md',
    output: 'architecture/data-models.md',
    section: 'architecture',
    order: 40,
    label: 'Data models',
  },
  {
    source: 'bridge-protocol.md',
    output: 'architecture/bridge-protocol.md',
    section: 'architecture',
    order: 50,
    label: 'Bridge protocol',
  },
  {
    source: 'integration/claude-code-hooks.md',
    output: 'integrations/claude-code-hooks.md',
    section: 'integrations',
    order: 10,
    label: 'Claude Code Hooks',
  },
  {
    source: 'integration/agent-sdk.md',
    output: 'integrations/agent-sdk.md',
    section: 'integrations',
    order: 20,
    label: 'Agent SDK',
  },
  {
    source: 'integration/opencode-ui-patterns.md',
    output: 'integrations/opencode-ui-patterns.md',
    section: 'integrations',
    order: 30,
    label: 'OpenCode UI patterns',
  },
  {
    source: 'security-architecture.md',
    output: 'operations/security-architecture.md',
    section: 'operations',
    order: 10,
    label: 'Security architecture',
  },
  {
    source: 'offline-architecture.md',
    output: 'operations/offline-architecture.md',
    section: 'operations',
    order: 20,
    label: 'Offline architecture',
  },
  {
    source: 'push-notifications.md',
    output: 'operations/push-notifications.md',
    section: 'operations',
    order: 30,
    label: 'Push notifications',
  },
  {
    source: 'ci-cd.md',
    output: 'operations/ci-cd.md',
    section: 'operations',
    order: 40,
    label: 'CI/CD',
  },
  {
    source: 'testing-strategy.md',
    output: 'operations/testing-strategy.md',
    section: 'operations',
    order: 50,
    label: 'Testing strategy',
  },
  {
    source: 'bridge-http-api.md',
    output: 'reference/bridge-http-api.md',
    section: 'reference',
    order: 10,
    label: 'Bridge HTTP API',
  },
  {
    source: 'error-handling.md',
    output: 'reference/error-handling.md',
    section: 'reference',
    order: 20,
    label: 'Error handling',
  },
  {
    source: 'type-mapping.md',
    output: 'reference/type-mapping.md',
    section: 'reference',
    order: 30,
    label: 'Type mapping',
  },
  {
    source: 'legal/privacy-policy.md',
    output: 'legal/privacy-policy.md',
    section: 'legal',
    order: 10,
    label: 'Privacy policy',
  },
  {
    source: 'legal/terms-of-service.md',
    output: 'legal/terms-of-service.md',
    section: 'legal',
    order: 20,
    label: 'Terms of service',
  },
];

export function toRoute(outputPath, base = '') {
  const normalized = outputPath.replace(/\\/g, '/');
  const withoutExtension = normalized.replace(/\.(md|mdx)$/i, '');
  const normalizedBase = base === '/' ? '' : base;
  const route = withoutExtension.endsWith('/index')
    ? `${normalizedBase}/${withoutExtension.slice(0, -6)}/`
    : `${normalizedBase}/${withoutExtension}/`;
  return route.replace(/\/+/g, '/');
}
