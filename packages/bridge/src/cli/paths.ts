import os from "os";
import path from "path";

export const RECURSOR_CLAUDE_PLUGIN_NAME = "recursor-bridge";
export const RECURSOR_LOCAL_MARKETPLACE_NAME = "recursor-local";

const CLAUDE_SETTINGS_DIR = ".claude";
const RECURSOR_LOCAL_MARKETPLACE_DIR = "claude-marketplace";

export interface ReCursorPaths {
  homeDir: string;
  configDir: string;
  configPath: string;
  certDir: string;
  claudeSettingsDir: string;
  claudeUserSettingsPath: string;
  recursorMarketplaceDir: string;
  claudePluginDir: string;
}

export function getClaudeMarketplaceManifestPath(marketplaceDir: string): string {
  return path.join(marketplaceDir, ".claude-plugin", "marketplace.json");
}

export function getClaudePluginManifestPath(pluginDir: string): string {
  return path.join(pluginDir, ".claude-plugin", "plugin.json");
}

export function getClaudePluginHooksPath(pluginDir: string): string {
  return path.join(pluginDir, "hooks", "hooks.json");
}

export function getReCursorPaths(): ReCursorPaths {
  const homeDir = os.homedir();
  const configDir = path.join(homeDir, ".recursor");
  const claudeSettingsDir = path.join(homeDir, CLAUDE_SETTINGS_DIR);
  const recursorMarketplaceDir = path.join(configDir, RECURSOR_LOCAL_MARKETPLACE_DIR);

  return {
    homeDir,
    configDir,
    configPath: path.join(configDir, "bridge-config.json"),
    certDir: path.join(configDir, "certs"),
    claudeSettingsDir,
    claudeUserSettingsPath: path.join(claudeSettingsDir, "settings.json"),
    recursorMarketplaceDir,
    claudePluginDir: path.join(recursorMarketplaceDir, "plugins", RECURSOR_CLAUDE_PLUGIN_NAME),
  };
}
