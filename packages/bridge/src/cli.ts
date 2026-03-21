#!/usr/bin/env node
import fs from "fs/promises";
import path from "path";
import crypto from "crypto";
import { spawn } from "child_process";
import readline from "readline/promises";
import { stdin as input, stdout as output } from "process";
import { fetchBridgeHealth, postHookEvent } from "./cli/http";
import {
  buildStoredConfig,
  ensureCliDirectories,
  loadStoredConfig,
  saveStoredConfig,
  type StoredBridgeConfig,
} from "./cli/config_store";
import {
  RECURSOR_CLAUDE_PLUGIN_NAME,
  RECURSOR_LOCAL_MARKETPLACE_NAME,
  getClaudeMarketplaceManifestPath,
  getClaudePluginHooksPath,
  getClaudePluginManifestPath,
  getReCursorPaths,
} from "./cli/paths";
import { installClaudePlugin } from "./cli/plugin_installer";
import { buildPairingPayload, renderPairingQr } from "./cli/qr";
import { getTransportProvider, listTransportProviders } from "./cli/transports/provider_registry";
import type {
  ConfigurableSetupOptions,
  ResolvedTransportSetup,
  RuntimeStartResult,
  SetupContext,
  TransportDetectionResult,
  TransportProviderId,
} from "./cli/transports/types";

interface SetupOptions extends ConfigurableSetupOptions {
  force: boolean;
  noStart: boolean;
  transport?: TransportProviderId;
}

interface StartOptions {
  showQr: boolean;
}

interface PackageMetadata {
  version?: unknown;
}

interface ClaudeInstalledPlugin {
  id: string;
  version?: string;
  scope?: string;
  enabled?: boolean;
  installPath?: string;
  installedAt?: string;
  lastUpdated?: string;
}

interface ClaudePluginSyncResult {
  pluginRef: string;
  pluginSourceDir: string;
  marketplaceDir: string;
  hookCommand: string;
  installedAt: string;
  pluginInstallPath?: string;
  repaired: boolean;
}

const GLOBAL_USAGE = `ReCursor CLI

Usage:
  recursor help [command]
  recursor version
  recursor setup [--force] [--no-start] [--transport=tailscale|cloudflare|ngrok|manual] [--port=3443] [--project-root=/path]
  recursor start [--qr]
  recursor qr
  recursor doctor [--verbose]
  recursor claude [-- <args passed to claude>]
  recursor hook-forward

Flags:
  -h, --help     Show usage information
  -v, --version  Show version information

Run \`recursor <command> --help\` for command-specific usage.
`;

const COMMAND_USAGE: Readonly<Record<string, string>> = {
  help: `Usage:\n  recursor help [command]\n\nShow global usage, or usage for a specific command.`,
  version: `Usage:\n  recursor version\n\nPrint the bridge CLI version.`,
  setup: `Usage:\n  recursor setup [--force] [--no-start] [--transport=tailscale|cloudflare|ngrok|manual] [--port=3443] [--project-root=/path]\n                 [--anthropic-api-key=<key>] [--hostname=<host>] [--tls-cert=/path] [--tls-key=/path]\n                 [--public-url=wss://bridge.example.com] [--local-mode=local-tls|upstream-proxy]\n\nConfigure the bridge CLI, install the Claude plugin, and optionally start the bridge immediately.`,
  start: `Usage:\n  recursor start [--qr]\n\nStart the bridge using the saved configuration.`,
  qr: `Usage:\n  recursor qr\n\nRender the pairing QR code for the saved bridge configuration.`,
  doctor: `Usage:\n  recursor doctor [--verbose]\n\nValidate the saved bridge configuration and print transport diagnostics.`,
  claude: `Usage:\n  recursor claude [-- <args passed to claude>]\n\nLaunch Claude with the installed ReCursor plugin hooks available.`,
  "hook-forward": `Usage:\n  recursor hook-forward\n\nRead a Claude hook event from stdin and forward it to the bridge.`,
};

function log(message: string): void {
  process.stdout.write(`${message}\n`);
}

function logError(message: string): void {
  process.stderr.write(`${message}\n`);
}

function parseValueArg(arg: string, flagName: string): string {
  const [, value] = arg.split("=", 2);
  if (!value) {
    throw new Error(`Missing value for ${flagName}`);
  }
  return value;
}

function parseTransportProviderId(value: string): TransportProviderId {
  if (value === "tailscale" || value === "cloudflare" || value === "ngrok" || value === "manual") {
    return value;
  }
  throw new Error(`Unsupported transport provider: ${value}`);
}

function parseSetupOptions(args: string[]): SetupOptions {
  const options: SetupOptions = {
    force: false,
    noStart: false,
    port: 3443,
    projectRoot: process.cwd(),
    anthropicApiKey: process.env.ANTHROPIC_API_KEY,
  };

  for (const arg of args) {
    if (arg === "--force") {
      options.force = true;
      continue;
    }
    if (arg === "--no-start") {
      options.noStart = true;
      continue;
    }
    if (arg.startsWith("--port=")) {
      options.port = Number.parseInt(parseValueArg(arg, "--port"), 10);
      continue;
    }
    if (arg.startsWith("--project-root=")) {
      options.projectRoot = path.resolve(parseValueArg(arg, "--project-root"));
      continue;
    }
    if (arg.startsWith("--anthropic-api-key=")) {
      options.anthropicApiKey = parseValueArg(arg, "--anthropic-api-key");
      continue;
    }
    if (arg.startsWith("--transport=")) {
      options.transport = parseTransportProviderId(parseValueArg(arg, "--transport"));
      continue;
    }
    if (arg.startsWith("--hostname=")) {
      options.hostname = parseValueArg(arg, "--hostname");
      continue;
    }
    if (arg.startsWith("--tls-cert=")) {
      options.tlsCertPath = path.resolve(parseValueArg(arg, "--tls-cert"));
      continue;
    }
    if (arg.startsWith("--tls-key=")) {
      options.tlsKeyPath = path.resolve(parseValueArg(arg, "--tls-key"));
      continue;
    }
    if (arg.startsWith("--public-url=")) {
      options.publicUrl = parseValueArg(arg, "--public-url");
      continue;
    }
    if (arg.startsWith("--local-mode=")) {
      const localMode = parseValueArg(arg, "--local-mode");
      if (localMode !== "local-tls" && localMode !== "upstream-proxy") {
        throw new Error("--local-mode must be either local-tls or upstream-proxy.");
      }
      options.localMode = localMode;
      continue;
    }

    throw new Error(`Unknown setup option: ${arg}`);
  }

  if (!Number.isInteger(options.port) || options.port <= 0) {
    throw new Error("--port must be a positive integer.");
  }

  return options;
}

function parseStartOptions(args: string[]): StartOptions {
  const options: StartOptions = {
    showQr: false,
  };

  for (const arg of args) {
    if (arg === "--qr") {
      options.showQr = true;
      continue;
    }

    throw new Error(`Unknown start option: ${arg}`);
  }

  return options;
}

function parseDoctorOptions(args: string[]): { verbose: boolean } {
  let verbose = false;

  for (const arg of args) {
    if (arg === "--verbose") {
      verbose = true;
      continue;
    }

    throw new Error(`Unknown doctor option: ${arg}`);
  }

  return { verbose };
}

function getCommandUsage(command: string): string | undefined {
  return COMMAND_USAGE[command];
}

function printUsage(command?: string): void {
  if (!command) {
    log(GLOBAL_USAGE);
    return;
  }

  const usage = getCommandUsage(command);
  if (!usage) {
    throw new Error(
      `Unknown help topic: ${command}. Run \`recursor help\` to see available commands.`,
    );
  }

  log(usage);
}

function isHelpFlag(arg: string): boolean {
  return arg === "--help" || arg === "-h";
}

function hasHelpFlag(args: string[]): boolean {
  return args.some(isHelpFlag);
}

function maskSecret(value: string): string {
  if (value.length <= 4) {
    return "*".repeat(value.length);
  }

  return `${"*".repeat(Math.max(4, value.length - 4))}${value.slice(-4)}`;
}

async function printVersion(): Promise<void> {
  const packageJsonPath = path.resolve(__dirname, "..", "package.json");
  const packageJsonRaw = await fs.readFile(packageJsonPath, "utf8");
  const packageMetadata = JSON.parse(packageJsonRaw) as PackageMetadata;

  if (typeof packageMetadata.version !== "string" || packageMetadata.version.length === 0) {
    throw new Error(`Bridge package version was not found in ${packageJsonPath}`);
  }

  log(packageMetadata.version);
}

function generateToken(prefix: string): string {
  return `${prefix}${crypto.randomBytes(24).toString("base64url")}`;
}

async function ensureFileExists(filePath: string, description: string): Promise<void> {
  try {
    await fs.access(filePath);
  } catch {
    throw new Error(`${description} was not found: ${filePath}`);
  }
}

function resolveCliScriptPath(): string {
  const currentScript = process.argv[1]
    ? path.resolve(process.argv[1])
    : path.resolve(__dirname, "cli.js");
  const compiledCli = path.resolve(__dirname, "cli.js");

  if (currentScript.endsWith(`${path.sep}src${path.sep}cli.ts`)) {
    return compiledCli;
  }

  return currentScript;
}

function quoteCliArgument(value: string): string {
  return `"${value.replace(/"/g, '\\"')}"`;
}

async function runClaudeCliCommand(
  args: string[],
): Promise<{ command: string; stdout: string; stderr: string }> {
  const command = ["claude", ...args.map(quoteCliArgument)].join(" ");

  return await new Promise<{ command: string; stdout: string; stderr: string }>(
    (resolve, reject) => {
      const child = spawn(command, {
        shell: true,
        stdio: ["ignore", "pipe", "pipe"],
      });

      let stdout = "";
      let stderr = "";

      child.stdout.on("data", (chunk: Buffer | string) => {
        stdout += chunk.toString();
      });
      child.stderr.on("data", (chunk: Buffer | string) => {
        stderr += chunk.toString();
      });

      child.on("error", (error) => {
        const errno = error as NodeJS.ErrnoException;
        if (errno.code === "ENOENT") {
          reject(new Error("Claude Code CLI was not found on PATH."));
          return;
        }
        reject(error);
      });
      child.on("close", (code) => {
        if (code === 0) {
          resolve({
            command,
            stdout: stdout.trim(),
            stderr: stderr.trim(),
          });
          return;
        }

        const details = stderr.trim() || stdout.trim() || `exit code ${code ?? "unknown"}`;
        reject(new Error(`Claude CLI command failed (${command}): ${details}`));
      });
    },
  );
}

function shouldIgnoreMissingPluginUninstall(error: unknown): boolean {
  const message = error instanceof Error ? error.message : String(error);
  return message.includes("not found in installed plugins");
}

async function installClaudePluginWithLocalMarketplace(input: {
  marketplaceDir: string;
  pluginRef: string;
}): Promise<void> {
  await runClaudeCliCommand(["plugin", "marketplace", "add", input.marketplaceDir]);

  try {
    await runClaudeCliCommand(["plugin", "uninstall", input.pluginRef, "--scope", "user"]);
  } catch (error) {
    if (!shouldIgnoreMissingPluginUninstall(error)) {
      throw error;
    }
  }

  await runClaudeCliCommand(["plugin", "install", input.pluginRef, "--scope", "user"]);
}

async function getClaudeInstalledPlugin(pluginRef: string): Promise<ClaudeInstalledPlugin | null> {
  const result = await runClaudeCliCommand(["plugin", "list", "--json"]);
  const parsed = JSON.parse(result.stdout) as unknown;

  if (!Array.isArray(parsed)) {
    throw new Error("Claude plugin list returned an unexpected JSON payload.");
  }

  for (const entry of parsed) {
    if (!entry || typeof entry !== "object") {
      continue;
    }

    const plugin = entry as ClaudeInstalledPlugin;
    if (plugin.id === pluginRef) {
      return plugin;
    }
  }

  return null;
}

async function ensureClaudePluginEnabled(pluginRef: string): Promise<ClaudeInstalledPlugin> {
  const plugin = await getClaudeInstalledPlugin(pluginRef);
  if (!plugin) {
    throw new Error(`Claude Code did not report ${pluginRef} as installed.`);
  }
  if (!plugin.enabled) {
    throw new Error(`Claude Code reported ${pluginRef} as installed but disabled.`);
  }
  return plugin;
}

async function readUtf8IfExists(filePath: string): Promise<string | null> {
  try {
    return await fs.readFile(filePath, "utf8");
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

async function needsClaudePluginRepair(input: {
  sourcePluginDir: string;
  pluginRef: string;
}): Promise<boolean> {
  const installedPlugin = await getClaudeInstalledPlugin(input.pluginRef);
  if (!installedPlugin || !installedPlugin.enabled || !installedPlugin.installPath) {
    return true;
  }

  const sourceManifest = await readUtf8IfExists(getClaudePluginManifestPath(input.sourcePluginDir));
  const sourceHooks = await readUtf8IfExists(getClaudePluginHooksPath(input.sourcePluginDir));
  const cachedManifest = await readUtf8IfExists(
    getClaudePluginManifestPath(installedPlugin.installPath),
  );
  const cachedHooks = await readUtf8IfExists(getClaudePluginHooksPath(installedPlugin.installPath));

  if (!sourceManifest || !sourceHooks || !cachedManifest || !cachedHooks) {
    return true;
  }

  return sourceManifest !== cachedManifest || sourceHooks !== cachedHooks;
}

async function syncClaudePluginInstallation(input: {
  paths: ReturnType<typeof getReCursorPaths>;
  cliScriptPath: string;
}): Promise<ClaudePluginSyncResult> {
  const pluginInstall = await installClaudePlugin({
    paths: input.paths,
    cliScriptPath: input.cliScriptPath,
  });

  const requiresRepair = await needsClaudePluginRepair({
    sourcePluginDir: pluginInstall.pluginDir,
    pluginRef: pluginInstall.pluginRef,
  });

  if (requiresRepair) {
    await installClaudePluginWithLocalMarketplace({
      marketplaceDir: pluginInstall.marketplaceDir,
      pluginRef: pluginInstall.pluginRef,
    });
  }

  const installedPlugin = await ensureClaudePluginEnabled(pluginInstall.pluginRef);
  return {
    pluginRef: pluginInstall.pluginRef,
    pluginSourceDir: pluginInstall.pluginDir,
    marketplaceDir: pluginInstall.marketplaceDir,
    hookCommand: pluginInstall.hookCommand,
    installedAt: pluginInstall.installedAt,
    pluginInstallPath: installedPlugin.installPath,
    repaired: requiresRepair,
  };
}

async function refreshClaudePluginState(
  paths: ReturnType<typeof getReCursorPaths>,
  config: StoredBridgeConfig,
): Promise<{ config: StoredBridgeConfig; pluginSync: ClaudePluginSyncResult }> {
  const pluginSync = await syncClaudePluginInstallation({
    paths,
    cliScriptPath: resolveCliScriptPath(),
  });

  const pluginConfigChanged =
    config.claudePlugin.pluginDir !== pluginSync.pluginSourceDir ||
    config.claudePlugin.hookCommand !== pluginSync.hookCommand ||
    config.claudePlugin.installedAt !== pluginSync.installedAt;

  if (!pluginConfigChanged) {
    return { config, pluginSync };
  }

  const nextConfig: StoredBridgeConfig = {
    ...config,
    updatedAt: new Date().toISOString(),
    claudePlugin: {
      pluginDir: pluginSync.pluginSourceDir,
      installedAt: pluginSync.installedAt,
      hookCommand: pluginSync.hookCommand,
    },
  };

  await saveStoredConfig(paths, nextConfig);
  return { config: nextConfig, pluginSync };
}

function isInteractive(): boolean {
  return Boolean(process.stdin.isTTY && process.stdout.isTTY);
}

async function promptText(message: string, defaultValue?: string): Promise<string> {
  if (!isInteractive()) {
    if (defaultValue !== undefined) {
      return defaultValue;
    }
    throw new Error(`${message} (interactive prompt required)`);
  }

  const rl = readline.createInterface({ input, output });
  try {
    const suffix = defaultValue ? ` [${defaultValue}]` : "";
    const answer = (await rl.question(`${message}${suffix}: `)).trim();
    return answer || defaultValue || "";
  } finally {
    rl.close();
  }
}

async function promptSelect(
  message: string,
  options: Array<{ value: string; label: string }>,
): Promise<string> {
  if (options.length === 0) {
    throw new Error("No options available to select.");
  }

  if (!isInteractive()) {
    return options[0].value;
  }

  log(message);
  options.forEach((option, index) => {
    log(`  ${index + 1}. ${option.label}`);
  });

  const rl = readline.createInterface({ input, output });
  try {
    const answer = (await rl.question(`Select [1-${options.length}] (default 1): `)).trim();
    const numeric = answer.length === 0 ? 1 : Number.parseInt(answer, 10);
    if (!Number.isInteger(numeric) || numeric < 1 || numeric > options.length) {
      throw new Error(`Selection must be between 1 and ${options.length}.`);
    }
    return options[numeric - 1].value;
  } finally {
    rl.close();
  }
}

function createSetupContext(
  options: SetupOptions,
  existingConfig: StoredBridgeConfig | null,
): SetupContext {
  return {
    paths: getReCursorPaths(),
    options,
    existingConfig,
    promptText,
    promptSelect,
    ensureFileExists,
  };
}

function printDetectionResults(results: TransportDetectionResult[]): void {
  log("Detected connection options:");
  results.forEach((result) => {
    const status = result.available ? "✔" : "✖";
    const recommendation = result.recommended ? " (recommended)" : "";
    const detail = result.available ? result.detail : result.reason;
    log(`  ${status} ${result.label}${recommendation}${detail ? ` — ${detail}` : ""}`);
  });
  log("");
}

function chooseDefaultProvider(results: TransportDetectionResult[]): TransportProviderId {
  const available = results.filter((result) => result.available);
  const recommended = available.find((result) => result.recommended);
  if (recommended) {
    return recommended.providerId;
  }
  if (available.length > 0) {
    return available[0].providerId;
  }
  throw new Error("No transport providers are currently available.");
}

function applyStoredConfigToEnv(config: StoredBridgeConfig): void {
  process.env.PORT = String(config.transport.localPort);
  process.env.BRIDGE_TOKEN = config.bridgeToken;
  process.env.HOOK_TOKEN = config.hookToken;
  process.env.ALLOWED_PROJECT_ROOT = config.allowedProjectRoot;

  if (config.transport.tlsTermination === "local" && config.transport.tls) {
    process.env.BRIDGE_TLS_CERT_PATH = config.transport.tls.certPath;
    process.env.BRIDGE_TLS_KEY_PATH = config.transport.tls.keyPath;
  } else {
    delete process.env.BRIDGE_TLS_CERT_PATH;
    delete process.env.BRIDGE_TLS_KEY_PATH;
  }

  if (config.anthropicApiKey) {
    process.env.ANTHROPIC_API_KEY = config.anthropicApiKey;
  } else {
    delete process.env.ANTHROPIC_API_KEY;
  }
}

function withResolvedPublicUrls(
  config: StoredBridgeConfig,
  runtimeResult: RuntimeStartResult,
): StoredBridgeConfig {
  if (!runtimeResult.publicWsUrl && !runtimeResult.publicHttpsUrl) {
    return config;
  }

  return {
    ...config,
    updatedAt: new Date().toISOString(),
    transport: {
      ...config.transport,
      publicWsUrl: runtimeResult.publicWsUrl ?? config.transport.publicWsUrl,
      publicHttpsUrl: runtimeResult.publicHttpsUrl ?? config.transport.publicHttpsUrl,
    },
  };
}

async function printPairingQr(config: StoredBridgeConfig): Promise<void> {
  const bridgeUrl = config.transport.publicWsUrl;
  if (!bridgeUrl) {
    throw new Error(
      "No public bridge URL is currently available. Start the bridge so the selected transport can publish one.",
    );
  }

  const qr = await renderPairingQr({
    url: bridgeUrl,
    token: config.bridgeToken,
  });

  log("Scan this QR code from ReCursor mobile:\n");
  process.stdout.write(qr);
  log("");
  log(`Pairing payload: ${buildPairingPayload({ url: bridgeUrl, token: config.bridgeToken })}`);
}

async function runBridgeForeground(
  paths: ReturnType<typeof getReCursorPaths>,
  config: StoredBridgeConfig,
  options: { showQr: boolean },
): Promise<void> {
  applyStoredConfigToEnv(config);
  const { createBridgeRuntime } = await import("./server");
  const runtime = await createBridgeRuntime();
  const provider = getTransportProvider(config.transport.provider);
  let activeConfig = config;
  let providerStop: (() => Promise<void>) | undefined;

  if (provider.startRuntime) {
    const runtimeResult = await provider.startRuntime({ config: activeConfig, log });
    activeConfig = withResolvedPublicUrls(activeConfig, runtimeResult);
    providerStop = runtimeResult.stop;
    await saveStoredConfig(paths, activeConfig);
  }

  let readyAnnounced = false;
  let postConnectionPluginCheckStarted = false;
  const unsubscribe = runtime.connectionManager.subscribe((snapshot) => {
    if (!readyAnnounced && snapshot.authenticatedClients > 0) {
      readyAnnounced = true;
      log("✔ Mobile connected and authenticated.");
      log("✔ ReCursor bridge is ready.");
    }

    if (!postConnectionPluginCheckStarted && snapshot.authenticatedClients > 0) {
      postConnectionPluginCheckStarted = true;
      void (async () => {
        try {
          const refreshed = await refreshClaudePluginState(paths, activeConfig);
          activeConfig = refreshed.config;
          if (refreshed.pluginSync.repaired) {
            log(`✔ Claude Code plugin re-synced: ${refreshed.pluginSync.pluginRef}`);
            if (refreshed.pluginSync.pluginInstallPath) {
              log(
                `✔ Claude Code plugin cache refreshed: ${refreshed.pluginSync.pluginInstallPath}`,
              );
            }
          } else {
            log(`✔ Claude Code plugin already current: ${refreshed.pluginSync.pluginRef}`);
          }
        } catch (error) {
          logError(
            `✖ Claude Code plugin post-connection check failed: ${error instanceof Error ? error.message : String(error)}`,
          );
        }
      })();
    }
  });

  log(`Transport: ${activeConfig.transport.label}`);
  if (activeConfig.transport.publicWsUrl) {
    log(`Bridge URL: ${activeConfig.transport.publicWsUrl}`);
  } else {
    log("Bridge URL: waiting for transport provider to publish a public URL");
  }
  if (activeConfig.transport.publicHttpsUrl) {
    log(`Health URL: ${activeConfig.transport.publicHttpsUrl}/api/v1/health`);
    log(`Hook endpoint: ${activeConfig.transport.publicHttpsUrl}/hooks/event`);
  }
  log(
    `Local origin: ${activeConfig.transport.localProtocol}://${activeConfig.transport.localHost}:${activeConfig.transport.localPort}`,
  );
  if (activeConfig.anthropicApiKey) {
    log("Agent SDK mode: enabled");
  } else {
    log("Agent SDK mode: disabled (hooks-only until ANTHROPIC_API_KEY is configured)");
  }

  if (options.showQr && activeConfig.transport.publicWsUrl) {
    await printPairingQr(activeConfig);
  } else if (options.showQr) {
    log("Public URL not yet available for QR generation.");
  }

  log("Waiting for mobile connection. Press Ctrl+C to stop.");

  await new Promise<void>((resolve, reject) => {
    let shuttingDown = false;

    const shutdown = (signal: string) => {
      if (shuttingDown) {
        return;
      }
      shuttingDown = true;
      log(`Received ${signal}, stopping bridge...`);
      unsubscribe();

      Promise.resolve()
        .then(() => providerStop?.())
        .then(() => runtime.stop())
        .then(() => resolve())
        .catch(reject);
    };

    process.once("SIGINT", () => shutdown("SIGINT"));
    process.once("SIGTERM", () => shutdown("SIGTERM"));
  });
}

async function resolveTransportSetup(
  context: SetupContext,
  requestedProvider?: TransportProviderId,
): Promise<ResolvedTransportSetup> {
  const providers = listTransportProviders();
  const detectionResults = await Promise.all(providers.map((provider) => provider.detect(context)));
  printDetectionResults(detectionResults);

  let providerId = requestedProvider;
  if (!providerId) {
    const availableOptions = detectionResults
      .filter((result) => result.available)
      .map((result) => ({
        value: result.providerId,
        label: `${result.label}${result.recommended ? " (recommended)" : ""}`,
      }));

    if (availableOptions.length === 0) {
      throw new Error("No usable transport providers were detected.");
    }

    providerId = isInteractive()
      ? ((await context.promptSelect(
          "Choose a connection mode:",
          availableOptions,
        )) as TransportProviderId)
      : chooseDefaultProvider(detectionResults);
  }

  const selectedDetection = detectionResults.find((result) => result.providerId === providerId);
  if (!selectedDetection?.available) {
    throw new Error(
      `Selected transport provider is not available: ${selectedDetection?.reason ?? providerId}`,
    );
  }

  const provider = getTransportProvider(providerId);
  return provider.setup(context);
}

function commandHelp(args: string[]): void {
  if (args.length === 0 || (args.length === 1 && args[0] === "--")) {
    printUsage();
    return;
  }

  if (args.length === 1) {
    const topic = args[0];
    if (isHelpFlag(topic)) {
      printUsage("help");
      return;
    }

    printUsage(topic);
    return;
  }

  throw new Error("Usage: recursor help [command]");
}

async function commandVersion(args: string[]): Promise<void> {
  if (hasHelpFlag(args)) {
    printUsage("version");
    return;
  }

  if (args.length > 0) {
    throw new Error(`Unknown version option: ${args[0]}`);
  }

  await printVersion();
}

async function commandSetup(args: string[]): Promise<void> {
  if (hasHelpFlag(args)) {
    printUsage("setup");
    return;
  }

  const options = parseSetupOptions(args);
  const paths = getReCursorPaths();
  await ensureCliDirectories(paths);

  const existingConfig = options.force ? null : await loadStoredConfig(paths);
  const setupContext = createSetupContext(options, existingConfig);
  const transportSetup = await resolveTransportSetup(setupContext, options.transport);
  const cliScriptPath = resolveCliScriptPath();
  const pluginInstall = await installClaudePlugin({ paths, cliScriptPath });

  const nextConfig = buildStoredConfig({
    bridgeToken: existingConfig?.bridgeToken ?? generateToken("rc_dev_"),
    hookToken: existingConfig?.hookToken ?? generateToken("rc_hook_"),
    allowedProjectRoot: options.projectRoot,
    anthropicApiKey: options.anthropicApiKey,
    transport: transportSetup.transport,
    claudePlugin: {
      pluginDir: pluginInstall.pluginDir,
      installedAt: pluginInstall.installedAt,
      hookCommand: pluginInstall.hookCommand,
    },
    existingCreatedAt: existingConfig?.createdAt,
  });

  await saveStoredConfig(paths, nextConfig);

  let pluginSync: ClaudePluginSyncResult;
  try {
    pluginSync = await syncClaudePluginInstallation({ paths, cliScriptPath });
  } catch (error) {
    throw new Error(
      `ReCursor bridge configuration was saved, but Claude plugin installation failed: ${error instanceof Error ? error.message : String(error)}`,
    );
  }

  log("✔ ReCursor CLI configuration saved.");
  log(`✔ Transport selected: ${nextConfig.transport.label}`);
  log(`✔ Local Claude marketplace prepared: ${pluginSync.marketplaceDir}`);
  log(`✔ Claude Code plugin installed globally: ${pluginSync.pluginRef}`);
  log(`✔ Claude Code plugin source: ${pluginSync.pluginSourceDir}`);
  for (const line of transportSetup.setupSummary) {
    log(`✔ ${line}`);
  }
  if (nextConfig.anthropicApiKey) {
    log("✔ Agent SDK features enabled for this bridge.");
  } else {
    log("ℹ Agent SDK features are disabled until ANTHROPIC_API_KEY is configured.");
  }

  if (options.noStart) {
    if (nextConfig.transport.publicUrlMode === "static") {
      await printPairingQr(nextConfig);
    } else {
      log(
        "Dynamic transport selected. Run `recursor start --qr` to launch the tunnel and display the pairing QR.",
      );
    }
    return;
  }

  await runBridgeForeground(paths, nextConfig, { showQr: true });
}

async function commandStart(args: string[]): Promise<void> {
  if (hasHelpFlag(args)) {
    printUsage("start");
    return;
  }

  const options = parseStartOptions(args);
  const paths = getReCursorPaths();
  const config = await loadStoredConfig(paths);

  if (!config) {
    throw new Error("No ReCursor bridge configuration found. Run `recursor setup` first.");
  }

  const refreshed = await refreshClaudePluginState(paths, config);
  if (refreshed.pluginSync.repaired) {
    log(`✔ Claude Code plugin repaired before bridge start: ${refreshed.pluginSync.pluginRef}`);
  }
  await runBridgeForeground(paths, refreshed.config, {
    showQr: options.showQr || refreshed.config.transport.publicUrlMode === "dynamic",
  });
}

async function commandQr(args: string[]): Promise<void> {
  if (hasHelpFlag(args)) {
    printUsage("qr");
    return;
  }

  if (args.length > 0) {
    throw new Error(`Unknown qr option: ${args[0]}`);
  }

  const paths = getReCursorPaths();
  const config = await loadStoredConfig(paths);

  if (!config) {
    throw new Error("No ReCursor bridge configuration found. Run `recursor setup` first.");
  }

  await printPairingQr(config);
}

async function commandDoctor(args: string[]): Promise<void> {
  if (hasHelpFlag(args)) {
    printUsage("doctor");
    return;
  }

  const options = parseDoctorOptions(args);
  const paths = getReCursorPaths();
  const config = await loadStoredConfig(paths);

  if (!config) {
    throw new Error("No ReCursor bridge configuration found. Run `recursor setup` first.");
  }

  const pluginRef = `${RECURSOR_CLAUDE_PLUGIN_NAME}@${RECURSOR_LOCAL_MARKETPLACE_NAME}`;

  if (config.transport.tls) {
    await ensureFileExists(config.transport.tls.certPath, "TLS certificate");
    await ensureFileExists(config.transport.tls.keyPath, "TLS private key");
  }
  await ensureFileExists(
    getClaudeMarketplaceManifestPath(paths.recursorMarketplaceDir),
    "Claude marketplace manifest",
  );
  await ensureFileExists(
    getClaudePluginManifestPath(config.claudePlugin.pluginDir),
    "Claude plugin manifest",
  );
  await ensureFileExists(
    getClaudePluginHooksPath(config.claudePlugin.pluginDir),
    "Claude plugin hooks.json",
  );
  const installedPlugin = await ensureClaudePluginEnabled(pluginRef);

  log("✔ Local configuration looks valid.");
  log(`Transport: ${config.transport.label}`);
  if (config.transport.publicWsUrl) {
    log(`Public bridge URL: ${config.transport.publicWsUrl}`);
  } else {
    log("Public bridge URL: dynamic, generated at runtime");
  }
  log(
    `Local origin: ${config.transport.localProtocol}://${config.transport.localHost}:${config.transport.localPort}`,
  );
  log(`Claude marketplace: ${RECURSOR_LOCAL_MARKETPLACE_NAME}`);
  log(`Claude plugin: ${pluginRef}`);
  log(`Claude plugin source: ${config.claudePlugin.pluginDir}`);
  if (installedPlugin.installPath) {
    log(`Claude plugin cache: ${installedPlugin.installPath}`);
  }

  if (options.verbose) {
    log("Verbose diagnostics:");
    log(`  Config path: ${paths.configPath}`);
    log(`  Claude user settings path: ${paths.claudeUserSettingsPath}`);
    log(`  Claude marketplace path: ${paths.recursorMarketplaceDir}`);
    log(`  Config version: ${config.version}`);
    log(`  Created at: ${config.createdAt}`);
    log(`  Updated at: ${config.updatedAt}`);
    log(`  Allowed project root: ${config.allowedProjectRoot}`);
    log(`  Bridge token: ${maskSecret(config.bridgeToken)}`);
    log(`  Hook token: ${maskSecret(config.hookToken)}`);
    log(
      `  Anthropic API key: ${config.anthropicApiKey ? maskSecret(config.anthropicApiKey) : "(not configured)"}`,
    );
    log(`  Hook command: ${config.claudePlugin.hookCommand}`);
    log(`  Plugin installed at: ${config.claudePlugin.installedAt}`);
    log(`  Claude plugin version: ${installedPlugin.version ?? "(unknown)"}`);
    log(`  Claude plugin scope: ${installedPlugin.scope ?? "(unknown)"}`);
    log(`  Transport provider id: ${config.transport.provider}`);
    log(`  Transport mode: ${config.transport.mode}`);
    log(`  Public URL mode: ${config.transport.publicUrlMode}`);
    log(`  TLS termination: ${config.transport.tlsTermination}`);
    if (config.transport.metadata) {
      log(`  Transport metadata: ${JSON.stringify(config.transport.metadata)}`);
    }
    if (config.transport.tls) {
      log(`  TLS hostname: ${config.transport.tls.hostname}`);
      log(`  TLS cert path: ${config.transport.tls.certPath}`);
      log(`  TLS key path: ${config.transport.tls.keyPath}`);
    }
  }

  const provider = getTransportProvider(config.transport.provider);
  if (provider.doctor) {
    for (const line of await provider.doctor({ config, log })) {
      log(line);
    }
  }

  if (!config.transport.publicHttpsUrl) {
    log(
      "Bridge health check skipped because the selected transport publishes a dynamic URL only after `recursor start` runs.",
    );
    return;
  }

  const health = await fetchBridgeHealth(config);
  if (health.ok) {
    log(`✔ Bridge health endpoint responded (${health.status}).`);
    log(health.body);
  } else if (health.message) {
    log(`✖ Bridge health check failed: ${health.message}`);
  } else {
    log(`✖ Bridge health endpoint returned ${health.status}.`);
    if (health.body) {
      log(health.body);
    }
  }
}

async function commandHookForward(args: string[]): Promise<void> {
  if (hasHelpFlag(args)) {
    printUsage("hook-forward");
    return;
  }

  if (args.length > 0) {
    throw new Error(`Unknown hook-forward option: ${args[0]}`);
  }

  const paths = getReCursorPaths();
  const config = await loadStoredConfig(paths);
  if (!config) {
    return;
  }

  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(String(chunk)));
  }

  const body = Buffer.concat(chunks).toString("utf8").trim();
  if (!body) {
    return;
  }

  try {
    const result = await postHookEvent(config, body);
    if (!result.ok) {
      logError(`[ReCursor] Hook forward failed with status ${result.status}: ${result.body}`);
    }
  } catch (error) {
    logError(
      `[ReCursor] Hook forward failed: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

async function commandClaude(args: string[]): Promise<void> {
  if (args[0] !== "--" && hasHelpFlag(args)) {
    printUsage("claude");
    return;
  }

  const paths = getReCursorPaths();
  const config = await loadStoredConfig(paths);
  if (!config) {
    throw new Error("No ReCursor bridge configuration found. Run `recursor setup` first.");
  }

  await ensureFileExists(
    getClaudePluginHooksPath(config.claudePlugin.pluginDir),
    "Claude plugin hooks.json",
  );
  await ensureClaudePluginEnabled(
    `${RECURSOR_CLAUDE_PLUGIN_NAME}@${RECURSOR_LOCAL_MARKETPLACE_NAME}`,
  );

  const claudeArgs = args[0] === "--" ? args.slice(1) : args;
  const command = ["claude", ...claudeArgs.map(quoteCliArgument)].join(" ");
  const child = spawn(command, {
    stdio: "inherit",
    shell: true,
  });

  await new Promise<void>((resolve, reject) => {
    child.on("exit", (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      reject(new Error(`Claude exited with code ${code ?? "unknown"}`));
    });
    child.on("error", reject);
  });
}

async function main(): Promise<void> {
  const [, , command, ...args] = process.argv;

  switch (command) {
    case undefined:
    case "--":
    case "--help":
    case "-h":
      printUsage();
      return;
    case "help":
      commandHelp(args);
      return;
    case "version":
    case "--version":
    case "-v":
      await commandVersion(args);
      return;
    case "setup":
      await commandSetup(args);
      return;
    case "start":
      await commandStart(args);
      return;
    case "qr":
      await commandQr(args);
      return;
    case "doctor":
      await commandDoctor(args);
      return;
    case "hook-forward":
      await commandHookForward(args);
      return;
    case "claude":
      await commandClaude(args);
      return;
    default:
      logError(`Unknown command: ${command}`);
      logError("Run `recursor help` to see available commands.");
      printUsage();
      process.exitCode = 1;
  }
}

main().catch((error) => {
  logError(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
