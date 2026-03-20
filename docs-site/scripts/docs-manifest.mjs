export const SITE_TITLE = 'ReCursor Docs';
export const SITE_DESCRIPTION =
  'Mobile-first companion UI for AI coding workflows, documented as a bridge-first Astro Starlight site.';

export const SECTION_ORDER = [
  'getting-started',
  'architecture',
  'integrations',
  'operations',
  'reference',
  'wireframes',
  'research',
  'legal',
];

export const SECTION_META = {
  'getting-started': {
    title: 'Getting started',
    description: 'Project overview, vision, and implementation plan.',
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
  wireframes: {
    title: 'Wireframes',
    description: 'Screen-by-screen mobile UX wireframes and navigation flows.',
  },
  research: {
    title: 'Research',
    description: 'Background research that informed the current documentation.',
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
    source: 'idea.md',
    output: 'getting-started/product-vision.md',
    section: 'getting-started',
    order: 20,
    label: 'Product vision',
  },
  {
    source: 'PLAN.md',
    output: 'getting-started/implementation-plan.md',
    section: 'getting-started',
    order: 30,
    label: 'Implementation plan',
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
    source: 'wireframes/README.md',
    output: 'wireframes/overview.md',
    section: 'wireframes',
    order: 10,
    label: 'Wireframes overview',
  },
  {
    source: 'wireframes/01-startup.md',
    output: 'wireframes/01-startup.md',
    section: 'wireframes',
    order: 20,
  },
  {
    source: 'wireframes/02-bridge.md',
    output: 'wireframes/02-bridge.md',
    section: 'wireframes',
    order: 30,
  },
  {
    source: 'wireframes/03-chat.md',
    output: 'wireframes/03-chat.md',
    section: 'wireframes',
    order: 40,
  },
  {
    source: 'wireframes/04-repos.md',
    output: 'wireframes/04-repos.md',
    section: 'wireframes',
    order: 50,
  },
  {
    source: 'wireframes/05-git.md',
    output: 'wireframes/05-git.md',
    section: 'wireframes',
    order: 60,
  },
  {
    source: 'wireframes/06-diff.md',
    output: 'wireframes/06-diff.md',
    section: 'wireframes',
    order: 70,
  },
  {
    source: 'wireframes/07-approvals.md',
    output: 'wireframes/07-approvals.md',
    section: 'wireframes',
    order: 80,
  },
  {
    source: 'wireframes/08-terminal.md',
    output: 'wireframes/08-terminal.md',
    section: 'wireframes',
    order: 90,
  },
  {
    source: 'wireframes/09-agents.md',
    output: 'wireframes/09-agents.md',
    section: 'wireframes',
    order: 100,
  },
  {
    source: 'wireframes/10-settings.md',
    output: 'wireframes/10-settings.md',
    section: 'wireframes',
    order: 110,
  },
  {
    source: 'wireframes/11-tablet.md',
    output: 'wireframes/11-tablet.md',
    section: 'wireframes',
    order: 120,
  },
  {
    source: 'research.md',
    output: 'research/overview.md',
    section: 'research',
    order: 10,
    label: 'Research overview',
  },
  {
    source: 'research/claude-remote-control-2026-03-17.md',
    output: 'research/claude-remote-control-2026-03-17.md',
    section: 'research',
    order: 20,
  },
  {
    source: 'research/claude-code-integration-feasibility-2026-03-17.md',
    output: 'research/claude-code-integration-feasibility-2026-03-17.md',
    section: 'research',
    order: 30,
  },
  {
    source: 'research/2026-documentation-stacks-research-2026-03-20.md',
    output: 'research/2026-documentation-stacks-research-2026-03-20.md',
    section: 'research',
    order: 40,
  },
  {
    source: 'research/benchmark-repos-mobile-claude-code-2026-03-20.md',
    output: 'research/benchmark-repos-mobile-claude-code-2026-03-20.md',
    section: 'research',
    order: 50,
  },
  {
    source: 'research/claude-code-mobile-repos-2026-03-20.md',
    output: 'research/claude-code-mobile-repos-2026-03-20.md',
    section: 'research',
    order: 60,
  },
  {
    source: 'research/mobile-companion-repos-2025-03-20.md',
    output: 'research/mobile-companion-repos-2025-03-20.md',
    section: 'research',
    order: 70,
  },
  {
    source: 'research/specs-grounded-in-benchmarks-2026-03-20.md',
    output: 'research/specs-grounded-in-benchmarks-2026-03-20.md',
    section: 'research',
    order: 80,
  },
  {
    source: 'research/tunnel-pairing-patterns-2026-03-20.md',
    output: 'research/tunnel-pairing-patterns-2026-03-20.md',
    section: 'research',
    order: 90,
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

export function toRoute(outputPath) {
  const normalized = outputPath.replace(/\\/g, '/');
  const withoutExtension = normalized.replace(/\.(md|mdx)$/i, '');
  if (withoutExtension.endsWith('/index')) {
    return `/${withoutExtension.slice(0, -6)}/`.replace(/\/+/g, '/');
  }
  return `/${withoutExtension}/`.replace(/\/+/g, '/');
}
