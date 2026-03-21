import fs from "fs/promises";
import path from "path";
import { VALID_EVENT_TYPES } from "../hooks/validator";
import {
  RECURSOR_CLAUDE_PLUGIN_NAME,
  RECURSOR_LOCAL_MARKETPLACE_NAME,
  getClaudeMarketplaceManifestPath,
  getClaudePluginHooksPath,
  getClaudePluginManifestPath,
  type ReCursorPaths,
} from "./paths";

export interface ClaudePluginInstallResult {
  pluginDir: string;
  marketplaceDir: string;
  marketplaceName: string;
  pluginRef: string;
  hookCommand: string;
  installedAt: string;
}

function quoteShellPath(value: string): string {
  return `"${value.replace(/"/g, '\\"')}"`;
}

function buildHookCommand(cliScriptPath: string): string {
  return `${quoteShellPath(process.execPath)} ${quoteShellPath(cliScriptPath)} hook-forward`;
}

function buildHooksDocument(hookCommand: string): string {
  const hookDefinition = {
    hooks: [
      {
        type: "command",
        command: hookCommand,
        timeout: 10,
      },
    ],
  };

  const hooks = Object.fromEntries(
    VALID_EVENT_TYPES.map((eventName) => [eventName, [hookDefinition]]),
  );

  return `${JSON.stringify(
    {
      description: "ReCursor bridge integration — forward Claude Code events to mobile app",
      hooks,
    },
    null,
    2,
  )}\n`;
}

function buildPluginManifest(): string {
  return `${JSON.stringify(
    {
      name: RECURSOR_CLAUDE_PLUGIN_NAME,
      version: "0.1.0",
      description: "Forwards Claude Code hook events to the ReCursor bridge CLI.",
    },
    null,
    2,
  )}\n`;
}

function buildMarketplaceManifest(): string {
  return `${JSON.stringify(
    {
      name: RECURSOR_LOCAL_MARKETPLACE_NAME,
      owner: {
        name: "ReCursor",
      },
      metadata: {
        description:
          "Private local marketplace used by ReCursor to install its Claude Code bridge plugin.",
      },
      plugins: [
        {
          name: RECURSOR_CLAUDE_PLUGIN_NAME,
          source: `./plugins/${RECURSOR_CLAUDE_PLUGIN_NAME}`,
        },
      ],
    },
    null,
    2,
  )}\n`;
}

function buildReadme(pluginDir: string, marketplaceDir: string): string {
  return `# ReCursor Claude Code Plugin\n\nThis plugin was installed by the ReCursor CLI through a private local Claude Code marketplace.\n\n- Marketplace directory: ${marketplaceDir}\n- Plugin directory: ${pluginDir}\n- Marketplace manifest: .claude-plugin/marketplace.json\n- Plugin manifest: .claude-plugin/plugin.json\n- Hook definitions: hooks/hooks.json\n- Re-run \`recursor setup\` to refresh the installed hook command\n`;
}

export async function installClaudePlugin(input: {
  paths: ReCursorPaths;
  cliScriptPath: string;
}): Promise<ClaudePluginInstallResult> {
  const marketplaceDir = input.paths.recursorMarketplaceDir;
  const marketplaceManifestDir = path.join(marketplaceDir, ".claude-plugin");
  const pluginDir = input.paths.claudePluginDir;
  const pluginManifestDir = path.join(pluginDir, ".claude-plugin");
  const hooksDir = path.join(pluginDir, "hooks");

  await fs.mkdir(marketplaceManifestDir, { recursive: true });
  await fs.mkdir(pluginManifestDir, { recursive: true });
  await fs.mkdir(hooksDir, { recursive: true });

  const hookCommand = buildHookCommand(input.cliScriptPath);
  const marketplaceJsonPath = getClaudeMarketplaceManifestPath(marketplaceDir);
  const pluginJsonPath = getClaudePluginManifestPath(pluginDir);
  const hooksJsonPath = getClaudePluginHooksPath(pluginDir);
  const readmePath = path.join(pluginDir, "README.md");
  const legacyHooksJsonPath = path.join(pluginDir, "hooks.json");
  const installedAt = new Date().toISOString();
  const pluginRef = `${RECURSOR_CLAUDE_PLUGIN_NAME}@${RECURSOR_LOCAL_MARKETPLACE_NAME}`;

  await fs.writeFile(marketplaceJsonPath, buildMarketplaceManifest(), "utf8");
  await fs.writeFile(pluginJsonPath, buildPluginManifest(), "utf8");
  await fs.writeFile(hooksJsonPath, buildHooksDocument(hookCommand), "utf8");
  await fs.writeFile(readmePath, buildReadme(pluginDir, marketplaceDir), "utf8");
  await fs.rm(legacyHooksJsonPath, { force: true });

  return {
    pluginDir,
    marketplaceDir,
    marketplaceName: RECURSOR_LOCAL_MARKETPLACE_NAME,
    pluginRef,
    hookCommand,
    installedAt,
  };
}
