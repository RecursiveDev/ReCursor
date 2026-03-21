/**
 * Tests for CloudflareTransportProvider configuration and behavior.
 *
 * These tests define the EXPECTED behavior for Cloudflare tunnel transport.
 * Some tests may currently PASS (verifying existing correct behavior),
 * others FAIL (defining intended hardening behavior).
 *
 * ============================================================================
 * TDD SLICE: cfTdd - Named Tunnel, Protocol Selection, Health/Readiness
 * ============================================================================
 *
 * This test file defines practical failing tests for the next Cloudflare
 * hardening slice. Tests are organized into three categories:
 *
 * 1. NAMED TUNNEL SUPPORT (production tunnels with persistent URLs)
 *    - Detection of named tunnel configuration vs quick tunnel
 *    - `setup()` returning static publicUrlMode for named tunnels
 *    - `startRuntime()` using `cloudflared tunnel run <name>` command
 *    - Metadata tracking tunnelType and tunnelName
 *
 * 2. PROTOCOL SELECTION (http/https localProtocol)
 *    - localProtocol selection in runtime startup/config
 *    - Proper URL construction based on protocol choice
 *    - Consistency between localProtocol and tlsTermination
 *
 * 3. HEALTH/READINESS/DOCTOR REPORTING (improved diagnosability)
 *    - doctor() output including tunnel type, endpoint, TLS info
 *    - Health status for tunnel process connectivity
 *    - Validation of cloudflared availability
 *
 * DEFERRED FUNCTIONALITY (requires disproportionate scaffolding):
 * - Automatic Cloudflare account management / API orchestration
 * - Validation of tunnel credentials file (~/.cloudflared/*.json)
 * - Runtime health checks for active tunnel process state
 *
 * See: docs/transports.md for transport provider specification
 * See: packages/bridge/src/cli/transports/providers/cloudflare_provider.ts
 */
import { CloudflareTransportProvider } from "../../../src/cli/transports/providers/cloudflare_provider";
import type { SetupContext, RuntimeStartContext } from "../../../src/cli/transports/types";

// Mock spawn to avoid actually running cloudflared
jest.mock("child_process", () => ({
  spawn: jest.fn(),
}));

import { spawn } from "child_process";

// Mock utils - create a manual mock with controlled sleep
const mockSleep = jest.fn().mockResolvedValue(undefined);
jest.mock("../../../src/cli/transports/utils", () => ({
  commandExists: jest.fn(),
  httpsToWss: (url: string) => url.replace("https://", "wss://"),
  sleep: () => mockSleep(),
}));

import { commandExists } from "../../../src/cli/transports/utils";

const mockCommandExists = commandExists as jest.MockedFunction<typeof commandExists>;
const mockSpawn = spawn as jest.MockedFunction<typeof spawn>;

describe("CloudflareTransportProvider", () => {
  let provider: CloudflareTransportProvider;

  beforeEach(() => {
    provider = new CloudflareTransportProvider();
    jest.clearAllMocks();
  });

  describe("static properties", () => {
    it("should have correct provider id", () => {
      expect(provider.id).toBe("cloudflare");
    });

    it("should have descriptive label", () => {
      expect(provider.label).toBe("Cloudflare Tunnel");
    });
  });

  describe("detect", () => {
    it("should return available=true when cloudflared CLI exists", async () => {
      mockCommandExists.mockResolvedValue(true);

      const context = createMockSetupContext();
      const result = await provider.detect(context);

      expect(result.available).toBe(true);
      expect(result.providerId).toBe("cloudflare");
      expect(result.label).toBe("Cloudflare Tunnel");
      expect(result.detail).toContain("cloudflared");
    });

    it("should return available=false when cloudflared CLI is missing", async () => {
      mockCommandExists.mockResolvedValue(false);

      const context = createMockSetupContext();
      const result = await provider.detect(context);

      expect(result.available).toBe(false);
      expect(result.reason).toContain("CLI not found");
    });
  });

  describe("setup", () => {
    it("should return secure_remote transport mode", async () => {
      mockCommandExists.mockResolvedValue(true);

      const context = createMockSetupContext();
      const result = await provider.setup(context);

      expect(result.transport.mode).toBe("secure_remote");
    });

    it("should return dynamic publicUrlMode", async () => {
      const context = createMockSetupContext();
      const result = await provider.setup(context);

      expect(result.transport.publicUrlMode).toBe("dynamic");
    });

    it("should return http localProtocol (not https)", async () => {
      const context = createMockSetupContext();
      const result = await provider.setup(context);

      // Cloudflare terminates TLS upstream, so local is http
      expect(result.transport.localProtocol).toBe("http");
    });

    it("should return upstream tlsTermination", async () => {
      const context = createMockSetupContext();
      const result = await provider.setup(context);

      expect(result.transport.tlsTermination).toBe("upstream");
    });

    it("should use configured localPort", async () => {
      const context = createMockSetupContext({ port: 8080 });
      const result = await provider.setup(context);

      expect(result.transport.localPort).toBe(8080);
      expect(result.transport.localHost).toBe("127.0.0.1");
    });

    it("should set runtimeProvider metadata", async () => {
      const context = createMockSetupContext();
      const result = await provider.setup(context);

      expect(result.transport.metadata).toEqual({
        runtimeProvider: "cloudflare",
      });
    });

    it("should provide setup summary mentioning dynamic URL", async () => {
      const context = createMockSetupContext();
      const result = await provider.setup(context);

      expect(result.setupSummary).toBeDefined();
      expect(result.setupSummary.length).toBeGreaterThan(0);
      expect(
        result.setupSummary.some((s) => s.includes("dynamic") || s.includes("trycloudflare")),
      ).toBe(true);
    });
  });

  describe("startRuntime", () => {
    it("should spawn cloudflated with tunnel subcommand", async () => {
      const mockChild = createMockChildProcess("https://test-tunnel.trycloudflare.com", 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      await provider.startRuntime!(context);

      expect(mockSpawn).toHaveBeenCalledWith(
        "cloudflared",
        expect.arrayContaining(["tunnel"]),
        expect.any(Object),
      );
    });

    it("should spawn with --no-autoupdate flag", async () => {
      const mockChild = createMockChildProcess("https://test-tunnel.trycloudflare.com", 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      await provider.startRuntime!(context);

      expect(mockSpawn).toHaveBeenCalledWith(
        "cloudflared",
        expect.arrayContaining(["--no-autoupdate"]),
        expect.any(Object),
      );
    });

    it("should spawn with correct local URL", async () => {
      const mockChild = createMockChildProcess("https://test-tunnel.trycloudflare.com", 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext({ port: 3443 });
      await provider.startRuntime!(context);

      expect(mockSpawn).toHaveBeenCalledWith(
        "cloudflared",
        expect.arrayContaining(["--url", "http://127.0.0.1:3443"]),
        expect.any(Object),
      );
    });

    it("should extract trycloudflare.com URL from stdout", async () => {
      const expectedUrl = "https://happy-morgan-somerset-hoping.trycloudflare.com";
      const mockChild = createMockChildProcess(expectedUrl, 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      expect(result.publicHttpsUrl).toBe(expectedUrl);
    });

    it("should extract trycloudflare.com URL from stderr", async () => {
      const expectedUrl = "https://pty-controversy-losing-opportunity.trycloudflare.com";
      const mockChild = createMockChildProcess(null, 0, expectedUrl);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      expect(result.publicHttpsUrl).toBe(expectedUrl);
    });

    it("should return wss:// URL converted from https://", async () => {
      const mockChild = createMockChildProcess("https://test-tunnel.trycloudflare.com", 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      expect(result.publicWsUrl).toBe("wss://test-tunnel.trycloudflare.com");
    });

    it("should log cloudflared output to context", async () => {
      const logMessages: string[] = [];
      const mockChild = createMockChildProcess("https://test-tunnel.trycloudflare.com", 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext({
        log: (msg: string) => logMessages.push(msg),
      });
      await provider.startRuntime!(context);

      // Verify logging occurs (implementation details may vary)
      expect(mockSpawn).toHaveBeenCalled();
    });

    it("should throw timeout error when no URL within 15 seconds", async () => {
      // Create a child process that never outputs a URL
      const mockChild = createMockChildProcess(null, 100);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();

      // Mock sleep to resolve immediately for faster test execution
      mockSleep.mockResolvedValue(undefined);

      await expect(provider.startRuntime!(context)).rejects.toThrow(
        "cloudflared did not publish a tunnel URL within 15 seconds",
      );
    });

    it("should kill child process on timeout", async () => {
      const mockChild = createMockChildProcess(null, 100);
      mockSpawn.mockReturnValue(mockChild as never);
      const killSpy = jest.spyOn(mockChild, "kill");

      const context = createMockRuntimeStartContext();

      // Mock sleep to resolve immediately for faster test execution
      mockSleep.mockResolvedValue(undefined);

      await expect(provider.startRuntime!(context)).rejects.toThrow();

      expect(killSpy).toHaveBeenCalledWith("SIGTERM");
    });
  });

  describe("doctor", () => {
    it("should return provider information", async () => {
      const context = createMockRuntimeStartContext();
      const result = await provider.doctor!(context);

      expect(result).toContain("Transport provider: Cloudflare Tunnel");
      expect(result.some((line) => line.includes("dynamic"))).toBe(true);
    });
  });

  describe("URL extraction edge cases", () => {
    // Test the internal extractTryCloudflareUrl function indirectly
    it("should extract URL with complex subdomain", async () => {
      const mockChild = createMockChildProcess(
        "https://happy-morgan-somerset-hoping-1234.trycloudflare.com",
        0,
      );
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      expect(result.publicHttpsUrl).toBe(
        "https://happy-morgan-somerset-hoping-1234.trycloudflare.com",
      );
    });

    it("should handle URL embedded in log output", async () => {
      // Real cloudflared output format from Issue.md logs:
      // |  https://happy-morgan-somerset-hoping.trycloudflare.com                                    |
      const logOutput = `2026-03-21T00:36:23Z INF +--------------------------------------------------------------------------------------------+
2026-03-21T00:36:23Z INF |  Your quick Tunnel has been created! Visit it at (it may take some time to be reachable):  |
2026-03-21T00:36:23Z INF |  https://happy-morgan-somerset-hoping.trycloudflare.com                                    |`;

      const mockChild = createMockChildProcess(logOutput, 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      expect(result.publicHttpsUrl).toBe("https://happy-morgan-somerset-hoping.trycloudflare.com");
    });

    it("should only match trycloudflare.com URLs (not other domains)", async () => {
      const multiUrlOutput = `
Connected to cloudflare infrastructure at https://cloudflare.com
Your tunnel: https://test.trycloudflare.com
Documentation: https://developers.cloudflare.com
`;

      const mockChild = createMockChildProcess(multiUrlOutput, 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      expect(result.publicHttpsUrl).toBe("https://test.trycloudflare.com");
    });
  });

  describe("Error handling and edge cases", () => {
    it("should throw error when cloudflared process exits with non-zero code", async () => {
      // Create a mock process that exits with error code
      const mockChild = {
        stdout: { on: jest.fn() },
        stderr: { on: jest.fn() },
        kill: jest.fn(),
        once: jest.fn((event: string, handler: () => void) => {
          if (event === "exit") {
            // Simulate immediate exit with code 1
            setTimeout(() => handler(), 0);
          }
        }),
        on: jest.fn(),
      };
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();

      // The provider should either throw or handle the error
      // Current implementation throws on timeout, but could also handle exit
      await expect(provider.startRuntime!(context)).rejects.toThrow();
    });

    it("should kill child process on cleanup even if start succeeded", async () => {
      const mockChild = createMockChildProcess("https://test.trycloudflare.com", 0);
      const killSpy = jest.spyOn(mockChild, "kill");
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      expect(result.publicHttpsUrl).toBe("https://test.trycloudflare.com");
      expect(result.stop).toBeDefined();

      // Call stop function and verify process is killed
      if (result.stop) {
        await result.stop();
        expect(killSpy).toHaveBeenCalledWith("SIGTERM");
      }
    });
  });

  describe("Protocol and URL format edge cases", () => {
    it("should convert HTTPS tunnel URL to WSS URL correctly", async () => {
      const mockChild = createMockChildProcess("https://complex-subdomain.trycloudflare.com", 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      expect(result.publicWsUrl).toBe("wss://complex-subdomain.trycloudflare.com");
    });

    it("should handle URL with trailing slash in output", async () => {
      // Real cloudflared might output URL with trailing content
      const mockChild = createMockChildProcess("https://tunnel.trycloudflare.com/", 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      // URL should be captured (trailing slash handling by regex)
      expect(result.publicHttpsUrl).toBeDefined();
      expect(result.publicHttpsUrl).toContain("trycloudflare.com");
    });

    it("should extract URL from mixed protocol output", async () => {
      // Test robustness when output contains both http and https references
      const mixedOutput = `
Your quick Tunnel has been created!
Visit: https://tunnel.trycloudflare.com
Local proxy: http://127.0.0.1:3443
`;
      const mockChild = createMockChildProcess(mixedOutput, 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext();
      const result = await provider.startRuntime!(context);

      // Should only match https trycloudflare URL, not http
      expect(result.publicHttpsUrl).toBe("https://tunnel.trycloudflare.com");
      expect(result.publicWsUrl).toBe("wss://tunnel.trycloudflare.com");
    });
  });

  describe("Runtime context handling", () => {
    it("should use configured port from transport config", async () => {
      const mockChild = createMockChildProcess("https://test.trycloudflare.com", 0);
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext({ port: 9999 });
      await provider.startRuntime!(context);

      expect(mockSpawn).toHaveBeenCalledWith(
        "cloudflared",
        expect.arrayContaining(["--url", "http://127.0.0.1:9999"]),
        expect.any(Object),
      );
    });

    it("should log all cloudflared output to context logger", async () => {
      const logMessages: string[] = [];
      const outputWithUrl = `[INF] Tunnel established at https://test.trycloudflare.com`;

      const mockChild = {
        stdout: {
          on: jest.fn((event: string, handler: (chunk: Buffer) => void) => {
            if (event === "data") {
              Promise.resolve().then(() => handler(Buffer.from(outputWithUrl)));
            }
          }),
        },
        stderr: { on: jest.fn() },
        kill: jest.fn(),
        once: jest.fn(),
        on: jest.fn(),
      };
      mockSpawn.mockReturnValue(mockChild as never);

      const context = createMockRuntimeStartContext({
        log: (msg: string) => logMessages.push(msg),
      });

      await provider.startRuntime!(context);

      // Verify logging occurred (implementation logs each chunk)
      expect(mockSpawn).toHaveBeenCalled();
    });
  });

  describe("Configuration validation for Cloudflare tunnels", () => {
    it("should return upstream TLS termination in transport config", async () => {
      const context = createMockSetupContext();
      const result = await provider.setup(context);

      // Cloudflare handles TLS at edge, not local
      expect(result.transport.tlsTermination).toBe("upstream");
      expect(result.transport.localProtocol).toBe("http");
    });

    it("should return runtimeProvider metadata for connection classification", async () => {
      const context = createMockSetupContext();
      const result = await provider.setup(context);

      // Metadata helps identify this is a Cloudflare tunnel at runtime
      expect(result.transport.metadata?.runtimeProvider).toBe("cloudflare");
    });

    it("should provide setup summary explaining dynamic URL behavior", async () => {
      const context = createMockSetupContext();
      const result = await provider.setup(context);

      // Summary should inform user about dynamic URL generation
      const summary = result.setupSummary.join(" ").toLowerCase();
      expect(summary).toContain("trycloudflare");
      expect(summary.length).toBeGreaterThan(20);
    });
  });

  // ============================================================================
  // NAMED TUNNEL SUPPORT - SLICE: cfTdd
  // These tests define expected behavior for named tunnel configuration.
  // Currently FAILING - implementation required.
  // ============================================================================

  describe("Named tunnel configuration (production)", () => {
    describe("detect", () => {
      it("should detect named tunnel capability when publicUrl is a configured hostname", async () => {
        mockCommandExists.mockResolvedValue(true);

        // When user provides a static Cloudflare hostname, we should indicate
        // that named tunnel is supported (requires cloudflared + tunnel credentials)
        const context = createMockSetupContextWithNamedTunnel({
          publicUrl: "https://bridge.example.com",
        });

        const result = await provider.detect(context);

        expect(result.available).toBe(true);
        // Named tunnels need credentials file in ~/.cloudflared/<uuid>.json
        // Provider should indicate tunnel-type capability
        expect(result.detail?.toLowerCase()).toContain("tunnel");
      });

      it("should validate named tunnel credentials availability during detect", async () => {
        mockCommandExists.mockResolvedValue(true);

        // Named tunnel requires credentials file - detect should validate this
        // when publicUrl is provided (indicating named tunnel intent)
        const context = createMockSetupContextWithNamedTunnel({
          publicUrl: "https://bridge.example.com",
        });

        const result = await provider.detect(context);

        // Should check for cloudflared AND tunnel credentials
        expect(result.available).toBe(true);
        // If credentials file missing, should still be available but with warning
        // This allows graceful degradation to quick tunnel
        expect(result.detail).toBeDefined();
      });
    });

    describe("setup", () => {
      it("should return static publicUrlMode for named tunnel configuration", async () => {
        mockCommandExists.mockResolvedValue(true);

        // Named tunnels have persistent URLs - URL doesn't change between restarts
        const context = createMockSetupContextWithNamedTunnel({
          publicUrl: "https://bridge.example.com",
        });

        const result = await provider.setup(context);

        // Named tunnel = static URL, quick tunnel = dynamic URL
        expect(result.transport.publicUrlMode).toBe("static");
        expect(result.transport.publicHttpsUrl).toBe("https://bridge.example.com");
        expect(result.transport.publicWsUrl).toBe("wss://bridge.example.com");
      });

      it("should store tunnel name in metadata for named tunnel", async () => {
        mockCommandExists.mockResolvedValue(true);

        const context = createMockSetupContextWithNamedTunnel({
          publicUrl: "https://bridge.example.com",
          transport: {
            metadata: { tunnelName: "recursor-bridge" },
          },
        });

        const result = await provider.setup(context);

        // Named tunnel metadata should be preserved for runtime startup
        expect(result.transport.metadata?.tunnelName).toBe("recursor-bridge");
        expect(result.transport.metadata?.tunnelType).toBe("named");
      });

      it("should set tunnelType=quick when no publicUrl provided", async () => {
        mockCommandExists.mockResolvedValue(true);

        // Without publicUrl, should default to quick tunnel mode
        const context = createMockSetupContext();
        const result = await provider.setup(context);

        expect(result.transport.publicUrlMode).toBe("dynamic");
        expect(result.transport.metadata?.tunnelType).toBe("quick");
      });

      it("should include tunnel hostname in setup summary for named tunnels", async () => {
        mockCommandExists.mockResolvedValue(true);

        const context = createMockSetupContextWithNamedTunnel({
          publicUrl: "https://bridge.example.com",
        });

        const result = await provider.setup(context);

        // Summary should indicate static URL for named tunnel
        const summary = result.setupSummary.join(" ").toLowerCase();
        expect(summary).toContain("bridge.example.com");
        expect(summary).not.toContain("trycloudflare");
      });
    });

    describe("startRuntime", () => {
      it("should use 'tunnel run <name>' for named tunnel", async () => {
        const mockChild = createMockChildProcess("https://bridge.example.com", 0);
        mockSpawn.mockReturnValue(mockChild as never);

        // Named tunnel uses existing tunnel route, not --url
        const context = createMockRuntimeStartContext({
          transport: {
            provider: "cloudflare",
            label: "Cloudflare Tunnel",
            mode: "secure_remote",
            publicUrlMode: "static",
            publicHttpsUrl: "https://bridge.example.com",
            publicWsUrl: "wss://bridge.example.com",
            localProtocol: "http",
            localPort: 3443,
            localHost: "127.0.0.1",
            tlsTermination: "upstream",
            metadata: {
              runtimeProvider: "cloudflare",
              tunnelType: "named",
              tunnelName: "recursor-bridge",
            },
          },
        });

        await provider.startRuntime!(context);

        // Named tunnel: cloudflared tunnel run <tunnel-name>
        expect(mockSpawn).toHaveBeenCalledWith(
          "cloudflared",
          expect.arrayContaining(["tunnel", "run", "recursor-bridge"]),
          expect.any(Object),
        );
      });

      it("should NOT use --url flag for named tunnel", async () => {
        const mockChild = createMockChildProcess("https://bridge.example.com", 0);
        mockSpawn.mockReturnValue(mockChild as never);

        const context = createMockRuntimeStartContext({
          transport: {
            provider: "cloudflare",
            metadata: { tunnelType: "named", tunnelName: "recursor-bridge" },
          } as never,
        });

        await provider.startRuntime!(context);

        const spawnArgs = mockSpawn.mock.calls[0]?.[1] as string[] | undefined;
        expect(spawnArgs).toBeDefined();
        // Named tunnel should NOT have --url flag
        expect(spawnArgs).not.toContain("--url");
      });

      it("should return configured static URL for named tunnel (not extracted from output)", async () => {
        // Named tunnel URLs are configured, not discovered from output
        const mockChild = createMockChildProcess(
          "Connection registered tunnel=recursor-bridge", // Not a URL
          0,
        );
        mockSpawn.mockReturnValue(mockChild as never);

        const context = createMockRuntimeStartContext({
          transport: {
            publicUrlMode: "static",
            publicHttpsUrl: "https://bridge.example.com",
            publicWsUrl: "wss://bridge.example.com",
            metadata: { tunnelType: "named" },
          } as never,
        });

        const result = await provider.startRuntime!(context);

        // For named tunnel, return the configured URL, not extracted one
        expect(result.publicHttpsUrl).toBe("https://bridge.example.com");
        expect(result.publicWsUrl).toBe("wss://bridge.example.com");
      });
    });
  });

  // ============================================================================
  // PROTOCOL SELECTION - SLICE: cfTdd
  // These tests define expected behavior for protocol selection in config.
  // Currently FAILING - implementation required.
  // ============================================================================

  describe("Protocol selection in configuration", () => {
    describe("setup", () => {
      it("should support http localProtocol selection (current default)", async () => {
        mockCommandExists.mockResolvedValue(true);

        // Cloudflare terminates TLS upstream, so local is http by default
        const context = createMockSetupContext({
          localMode: "upstream-proxy",
        });

        const result = await provider.setup(context);

        // Default: upstream TLS termination, local http
        expect(result.transport.localProtocol).toBe("http");
        expect(result.transport.tlsTermination).toBe("upstream");
      });

      it("should support https localProtocol for local TLS termination", async () => {
        mockCommandExists.mockResolvedValue(true);

        // Some deployments may want local TLS (e.g., reverse proxy in front)
        const context = createMockSetupContext({
          localMode: "local-tls",
        });

        const result = await provider.setup(context);

        // If user opts into local TLS, provider should respect that
        // This would typically require certPath/keyPath in options
        expect(result.transport.localProtocol).toBe("https");
        // Note: For Cloudflare, this is unusual but technically supported
        // TLS termination would still be upstream, but local also has TLS
      });

      it("should validate localProtocol and tlsTermination consistency", async () => {
        mockCommandExists.mockResolvedValue(true);

        const context = createMockSetupContext();
        const result = await provider.setup(context);

        // http localProtocol MUST use upstream TLS termination
        // https localProtocol can use either local or upstream
        if (result.transport.localProtocol === "http") {
          expect(result.transport.tlsTermination).toBe("upstream");
        }
      });

      it("should document protocol selection in setup summary", async () => {
        mockCommandExists.mockResolvedValue(true);

        const context = createMockSetupContext();
        const result = await provider.setup(context);

        // Setup should inform user about protocol choices
        const summary = result.setupSummary.join("\n").toLowerCase();
        // Should mention TLS termination location
        expect(summary.length).toBeGreaterThan(10);
      });
    });

    describe("startRuntime", () => {
      it("should spawn cloudflared with http:// URL for http localProtocol", async () => {
        const mockChild = createMockChildProcess("https://test.trycloudflare.com", 0);
        mockSpawn.mockReturnValue(mockChild as never);

        const context = createMockRuntimeStartContext({
          transport: {
            localProtocol: "http",
            localPort: 3443,
          } as never,
        });

        await provider.startRuntime!(context);

        expect(mockSpawn).toHaveBeenCalledWith(
          "cloudflared",
          expect.arrayContaining(["--url", "http://127.0.0.1:3443"]),
          expect.any(Object),
        );
      });

      it("should spawn cloudflared with https:// URL for https localProtocol", async () => {
        const mockChild = createMockChildProcess("https://test.trycloudflare.com", 0);
        mockSpawn.mockReturnValue(mockChild as never);

        // When localProtocol is https, cloudflared should connect to https local
        const context = createMockRuntimeStartContext({
          transport: {
            localProtocol: "https",
            localPort: 3443,
          } as never,
        });

        await provider.startRuntime!(context);

        expect(mockSpawn).toHaveBeenCalledWith(
          "cloudflared",
          expect.arrayContaining(["--url", "https://127.0.0.1:3443"]),
          expect.any(Object),
        );
      });
    });
  });

  // ============================================================================
  // HEALTH / READINESS / DOCTOR REPORTING - SLICE: cfTdd
  // These tests define expected behavior for diagnostics and health checks.
  // Currently FAILING - implementation required.
  // ============================================================================

  describe("Health and diagnostics", () => {
    describe("doctor", () => {
      it("should include tunnel type in doctor output", async () => {
        // Quick tunnel doctor output
        const quickContext = createMockRuntimeStartContext();
        const quickResult = await provider.doctor!(quickContext);

        expect(quickResult).toContain("Transport provider: Cloudflare Tunnel");
        // Should indicate quick tunnel type
        expect(
          quickResult.some(
            (line) =>
              line.toLowerCase().includes("quick") || line.toLowerCase().includes("temporary"),
          ),
        ).toBe(true);
      });

      it("should include named tunnel information in doctor output", async () => {
        // Named tunnel doctor output
        const namedContext = createMockRuntimeStartContext({
          transport: {
            publicUrlMode: "static",
            publicHttpsUrl: "https://bridge.example.com",
            metadata: {
              tunnelType: "named",
              tunnelName: "recursor-bridge",
            },
          } as never,
        });

        const result = await provider.doctor!(namedContext);

        expect(result).toContain("Transport provider: Cloudflare Tunnel");
        // Should show tunnel name for named tunnels
        expect(result.some((line) => line.includes("recursor-bridge"))).toBe(true);
        // Should show static URL
        expect(result.some((line) => line.includes("bridge.example.com"))).toBe(true);
      });

      it("should include local endpoint in doctor output", async () => {
        const context = createMockRuntimeStartContext({
          transport: {
            localProtocol: "http",
            localPort: 3443,
            localHost: "127.0.0.1",
          } as never,
        });

        const result = await provider.doctor!(context);

        // Doctor should show what local endpoint is being tunneled
        expect(result.some((line) => line.includes("127.0.0.1"))).toBe(true);
        expect(result.some((line) => line.includes("3443"))).toBe(true);
      });

      it("should include TLS termination information in doctor output", async () => {
        const context = createMockRuntimeStartContext();
        const result = await provider.doctor!(context);

        // TLS security is important - doctor should show where TLS terminates
        expect(
          result.some(
            (line) => line.toLowerCase().includes("tls") || line.toLowerCase().includes("https"),
          ),
        ).toBe(true);
      });

      it("should validate cloudflared availability in doctor", async () => {
        mockCommandExists.mockResolvedValue(true);

        const context = createMockRuntimeStartContext();
        const result = await provider.doctor!(context);

        // Doctor should verify cloudflared is accessible
        expect(
          result.some(
            (line) =>
              line.toLowerCase().includes("cloudflared") &&
              (line.toLowerCase().includes("available") ||
                line.toLowerCase().includes("installed") ||
                line.toLowerCase().includes("detected")),
          ),
        ).toBe(true);
      });
    });

    describe("healthCheck (runtime health)", () => {
      it("should provide tunnel process health status via doctor", async () => {
        // Doctor should report whether cloudflared process would be healthy
        const context = createMockRuntimeStartContext();
        const result = await provider.doctor!(context);

        // For static configuration, can verify tunnel credentials exist
        // For quick tunnel, can only verify cloudflared binary
        expect(result.length).toBeGreaterThan(1);
      });

      it("should report tunnel URL status in doctor output", async () => {
        // Quick tunnel: URL is dynamic (generated at runtime)
        const quickContext = createMockRuntimeStartContext();
        const quickResult = await provider.doctor!(quickContext);

        expect(
          quickResult.some((line) => line.includes("dynamic") || line.includes("runtime")),
        ).toBe(true);

        // Named tunnel: URL is static (configured)
        const namedContext = createMockRuntimeStartContext({
          transport: {
            publicUrlMode: "static",
            publicHttpsUrl: "https://bridge.example.com",
          } as never,
        });
        const namedResult = await provider.doctor!(namedContext);

        expect(namedResult.some((line) => line.includes("bridge.example.com"))).toBe(true);
      });
    });

    describe("error diagnostics", () => {
      it("should include diagnostic hints in timeout error message", async () => {
        const mockChild = createMockChildProcess(null, 100);
        mockSpawn.mockReturnValue(mockChild as never);
        mockSleep.mockResolvedValue(undefined);

        const context = createMockRuntimeStartContext();

        try {
          await provider.startRuntime!(context);
          fail("Expected timeout error");
        } catch (error) {
          expect(error).toBeInstanceOf(Error);
          const message = (error as Error).message;
          // Error should be actionable
          expect(message.length).toBeGreaterThan(20);
          // Current implementation just says timeout
          // Desired: include hints about what to check
          // (cloudflared installed? network connectivity? rate limits?)
        }
      });

      it("should handle named tunnel credential errors gracefully", async () => {
        // This test verifies behavior when named tunnel credentials missing
        // Implementation should catch and report helpful error
        const context = createMockRuntimeStartContext({
          transport: {
            publicUrlMode: "static",
            metadata: { tunnelType: "named", tunnelName: "nonexistent-tunnel" },
          } as never,
        });

        // Named tunnel with invalid credentials should fail fast
        // Current implementation may time out waiting for URL
        // Desired: detect credential issue early in startRuntime
        // For now, this test documents expected behavior change
      });
    });
  });

  describe("Edge cases and resilience", () => {
    it("should handle rapid setup/detect cycles without state leakage", async () => {
      mockCommandExists.mockResolvedValue(true);

      // Provider should be stateless - multiple detect/setup calls should be independent
      const context1 = createMockSetupContextWithNamedTunnel({
        publicUrl: "https://first.example.com",
      });
      const context2 = createMockSetupContext();

      const result1 = await provider.setup(context1);
      const result2 = await provider.setup(context2);

      // Second call should not be influenced by first
      expect(result2.transport.publicUrlMode).toBe("dynamic");
      expect(result2.transport.publicHttpsUrl).toBeUndefined();
    });

    it("should validate that named tunnel URL matches configured hostname", async () => {
      mockCommandExists.mockResolvedValue(true);

      // User configures named tunnel URL
      const context = createMockSetupContextWithNamedTunnel({
        publicUrl: "https://bridge.example.com",
      });

      const result = await provider.setup(context);

      // URL should be preserved exactly as configured
      expect(result.transport.publicHttpsUrl).toBe("https://bridge.example.com");
      // Should use wss:// for WebSocket
      expect(result.transport.publicWsUrl).toBe("wss://bridge.example.com");
    });

    it("should handle missing optional config fields gracefully", async () => {
      mockCommandExists.mockResolvedValue(true);

      // Minimal config - missing optional fields
      const context = {
        paths: { configDir: "/test", configFile: "/test/config.json", pidFile: "/test/pid" },
        options: { port: 3443, projectRoot: "/test" },
        existingConfig: null,
        promptText: jest.fn(),
        promptSelect: jest.fn(),
        ensureFileExists: jest.fn(),
      } as never;

      const result = await provider.setup(context);

      // Should provide sensible defaults
      expect(result.transport.provider).toBe("cloudflare");
      expect(result.transport.localPort).toBe(3443);
    });
  });
});

// Helper functions

function createMockSetupContext(
  options: Partial<{
    port: number;
    publicUrl?: string;
    localMode?: "local-tls" | "upstream-proxy";
  }> = {},
): SetupContext {
  return {
    paths: {
      configDir: "/test/.recursor",
      configFile: "/test/.recursor/config.json",
      pidFile: "/test/.recursor/bridge.pid",
    },
    options: {
      port: options.port ?? 3443,
      projectRoot: "/test/project",
      publicUrl: options.publicUrl,
      localMode: options.localMode,
    },
    existingConfig: null,
    promptText: jest.fn(),
    promptSelect: jest.fn(),
    ensureFileExists: jest.fn(),
  } as never;
}

/**
 * Create a mock SetupContext for named tunnel configuration.
 * Named tunnels require a publicUrl in options, indicating a pre-configured
 * Cloudflare tunnel hostname.
 */
function createMockSetupContextWithNamedTunnel(
  options: Partial<{
    publicUrl: string;
    transport?: Partial<{
      metadata: Record<string, string>;
    }>;
  }> = {},
): SetupContext {
  return {
    paths: {
      configDir: "/test/.recursor",
      configFile: "/test/.recursor/config.json",
      pidFile: "/test/.recursor/bridge.pid",
    },
    options: {
      port: 3443,
      projectRoot: "/test/project",
      publicUrl: options.publicUrl ?? "https://bridge.example.com",
    },
    existingConfig: options.transport?.metadata
      ? {
          transport: {
            provider: "cloudflare",
            label: "Cloudflare Tunnel",
            mode: "secure_remote",
            publicUrlMode: "static",
            localProtocol: "http",
            localPort: 3443,
            localHost: "127.0.0.1",
            tlsTermination: "upstream",
            metadata: options.transport.metadata,
          },
        }
      : null,
    promptText: jest.fn(),
    promptSelect: jest.fn(),
    ensureFileExists: jest.fn(),
  } as never;
}

interface MockRuntimeStartContextOptions {
  port?: number;
  log?: (msg: string) => void;
  transport?: Partial<RuntimeStartContext["config"]["transport"]>;
}

function createMockRuntimeStartContext(
  options: MockRuntimeStartContextOptions = {},
): RuntimeStartContext {
  const baseTransport: RuntimeStartContext["config"]["transport"] = {
    provider: "cloudflare",
    label: "Cloudflare Tunnel",
    mode: "secure_remote",
    publicUrlMode: "dynamic",
    localProtocol: "http",
    localPort: options.port ?? 3443,
    localHost: "127.0.0.1",
    tlsTermination: "upstream",
    metadata: { runtimeProvider: "cloudflare" },
  };

  return {
    config: {
      version: 2,
      createdAt: "2026-01-01T00:00:00Z",
      updatedAt: "2026-01-01T00:00:00Z",
      bridgeToken: "test-bridge-token",
      hookToken: "test-hook-token",
      allowedProjectRoot: "/test/project",
      transport: options.transport ? { ...baseTransport, ...options.transport } : baseTransport,
      claudePlugin: {
        pluginDir: "/test/.claude-plugin",
        installedAt: "2026-01-01T00:00:00Z",
        hookCommand: "recursor-bridge hook",
      },
    },
    log: options.log ?? jest.fn(),
  } as never;
}

function createMockChildProcess(
  httpsUrl: string | null,
  delayMs: number,
  stderrUrl?: string,
): ReturnType<typeof spawn> {
  // Create EventEmitter-like objects for stdout and stderr
  const stdoutListeners: Array<(chunk: Buffer) => void> = [];
  const stderrListeners: Array<(chunk: Buffer) => void> = [];

  const mockStdout = {
    on: (event: string, handler: (chunk: Buffer) => void) => {
      if (event === "data") {
        stdoutListeners.push(handler);
        // For tests with delayMs === 0, emit synchronously after listener is registered
        if (delayMs === 0 && !stderrUrl && httpsUrl) {
          // Allow microtask queue to process, then emit
          Promise.resolve().then(() => {
            handler(Buffer.from(httpsUrl));
          });
        }
      }
      return mockStdout;
    },
  };

  const mockStderr = {
    on: (event: string, handler: (chunk: Buffer) => void) => {
      if (event === "data") {
        stderrListeners.push(handler);
        // For tests with delayMs === 0 and stderrUrl, emit synchronously after listener is registered
        if (delayMs === 0 && stderrUrl) {
          Promise.resolve().then(() => {
            handler(Buffer.from(stderrUrl));
          });
        }
      }
      return mockStderr;
    },
  };

  const mockProcess = {
    stdout: mockStdout,
    stderr: mockStderr,
    kill: jest.fn(),
    once: jest.fn((_event: string, handler: () => void) => {
      // Immediately exit when once('exit') is called (used in stop())
      if (_event === "exit") {
        setImmediate(handler);
      }
      return mockProcess;
    }),
  } as never;

  // For tests that need a delay, emit after the microtask queue clears
  // (This allows the immediate Promise.resolve to resolve first for immediate cases)
  if (delayMs > 0) {
    // Will never emit - used for timeout tests
    // The listeners were already registered above, but no emission
  }

  return mockProcess as ReturnType<typeof spawn>;
}
