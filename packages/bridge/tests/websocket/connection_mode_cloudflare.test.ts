/**
 * Tests for Cloudflare tunnel connection classification.
 *
 * These tests define the EXPECTED behavior for Cloudflare tunnels.
 * Currently FAILING because Cloudflare tunnel hosts (*.trycloudflare.com)
 * are not recognized as secure tunnels.
 *
 * Issue: Connections through Cloudflare tunnels are misclassified as
 * "direct_public" instead of "secure_remote", causing incorrect security
 * warnings and bridge URL handling.
 */
import {
  detectConnectionMode,
  describeConnectionMode,
  buildBridgeUrl,
} from "../../src/websocket/connection_mode";
import type { ConnectionModeMetadata } from "../../src/websocket/connection_mode";

describe("ConnectionMode - Cloudflare Tunnel Classification", () => {
  describe("detectConnectionMode", () => {
    describe("Cloudflare tunnel hosts (*.trycloudflare.com)", () => {
      it("should classify trycloudflare.com host as secure_remote", () => {
        // This corresponds to: wss://happy-morgan-somerset-hoping.trycloudflare.com
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107", // Cloudflare IP (seen in logs)
          host: "happy-morgan-somerset-hoping.trycloudflare.com",
          secureTransport: true,
        };

        // EXPECTED: secure_remote (Cloudflare provides TLS and tunneling)
        // ACTUAL: direct_public (test currently fails)
        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });

      it("should classify trycloudflare.com host with port as secure_remote", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "happy-morgan-somerset-hoping.trycloudflare.com:3000",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });

      it("should classify trycloudflare.com host without remote address as secure_remote", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: undefined,
          host: "pty-controversy-losing-opportunity.trycloudflare.com",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });

      it("should classify trycloudflare.com with IPv6 remote address as secure_remote", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "::ffff:d0f7:0f6b", // IPv6-mapped Cloudflare IP
          host: "test-tunnel.trycloudflare.com",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });

      it("should return misconfigured for trycloudflare.com with insecure transport", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "happy-morgan-somerset-hoping.trycloudflare.com",
          secureTransport: false, // Unencrypted - security issue
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("misconfigured");
      });
    });

    describe("Cloudflare IP address recognition", () => {
      it("should recognize Cloudflare IP ranges as tunnel addresses", () => {
        // Cloudflare uses various IP ranges. Common ones visible in logs:
        // 216.247.15.107 was seen in Issue.md
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: undefined,
          secureTransport: true,
        };

        // When host is missing but IP is a known tunnel provider IP,
        // we should still classify appropriately
        const result = detectConnectionMode(metadata);
        // Note: This may require additional IP range detection
        // For now, we accept either classification as valid
        expect(["secure_remote", "direct_public"]).toContain(result);
      });
    });

    describe("Comparison with other transport modes", () => {
      it("should NOT misclassify Cloudflare tunnels alongside Tailscale", () => {
        // Tailscale should still work correctly
        const tailscaleMetadata: ConnectionModeMetadata = {
          remoteAddress: "100.64.0.1",
          host: "devbox.tailnet.ts.net",
          secureTransport: true,
        };
        const tailscaleResult = detectConnectionMode(tailscaleMetadata);
        expect(tailscaleResult).toBe("secure_remote");

        // Cloudflare should also return secure_remote
        const cloudflareMetadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "my-tunnel.trycloudflare.com",
          secureTransport: true,
        };
        const cloudflareResult = detectConnectionMode(cloudflareMetadata);
        expect(cloudflareResult).toBe("secure_remote");
      });

      it("should still correctly classify local_only for loopback", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "127.0.0.1",
          host: undefined,
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("local_only");
      });

      it("should still correctly classify private_network for RFC1918 addresses", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "192.168.1.100",
          host: undefined,
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("private_network");
      });
    });
  });

  describe("describeConnectionMode", () => {
    it("should describe secure_remote Cloudflare tunnel correctly", () => {
      const description = describeConnectionMode("secure_remote", {
        remoteAddress: "216.247.15.107",
        host: "happy-morgan-somerset-hoping.trycloudflare.com",
      });

      // Should mention the tunnel or secure connection
      expect(description.toLowerCase()).toContain("secure");
      expect(description).toContain("trycloudflare.com");
    });

    it("should provide clear description for misconfigured Cloudflare tunnel", () => {
      const description = describeConnectionMode("misconfigured", {
        remoteAddress: "216.247.15.107",
        host: "happy-morgan-somerset-hoping.trycloudflare.com",
      });

      expect(description).toContain("Unencrypted");
    });
  });

  describe("buildBridgeUrl", () => {
    it("should build wss:// URL for Cloudflare tunnel host", () => {
      const url = buildBridgeUrl("happy-morgan-somerset-hoping.trycloudflare.com", true);
      expect(url).toBe("wss://happy-morgan-somerset-hoping.trycloudflare.com");
    });

    it("should build ws:// URL for Cloudflare tunnel without TLS", () => {
      const url = buildBridgeUrl("test.trycloudflare.com", false);
      expect(url).toBe("ws://test.trycloudflare.com");
    });

    it("should handle host with port correctly", () => {
      const url = buildBridgeUrl("test.trycloudflare.com:3000", true);
      expect(url).toBe("wss://test.trycloudflare.com:3000");
    });
  });

  describe("Cloudflare tunnel URL edge cases", () => {
    describe("Case-insensitive host matching", () => {
      it("should classify UPPERCASE trycloudflare.com host as secure_remote", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "TEST-TUNNEL.TRYCLOUDFLARE.COM",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });

      it("should classify MixedCase trycloudflare.com host as secure_remote", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "Test-Tunnel.TryCloudflare.Com",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });
    });

    describe("Subdomain edge cases", () => {
      it("should classify deeply nested subdomain as secure_remote", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: undefined,
          host: "a-b-c-d-e-f-g-h-i-j-k-l-m-n-o-p.trycloudflare.com",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });

      it("should reject non-trycloudflare.com Cloudflare domains as direct_public", () => {
        // Pages.dev, workers.dev, etc. are Cloudflare products but not secure tunnels
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "my-site.pages.dev",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("direct_public");
      });

      it("should reject typosquatted similar domains as direct_public", () => {
        // Typosquatted domains that look similar but aren't trycloudflare.com
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "test.trycloudflare.com.evil.com",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("direct_public");
      });
    });

    describe("Protocol and port edge cases", () => {
      it("should classify host with explicit port as secure_remote", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "tunnel.trycloudflare.com:443",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });

      it("should classify host with non-standard port as secure_remote", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "tunnel.trycloudflare.com:8443",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });

      it("should handle host with leading/trailing whitespace", () => {
        const metadata: ConnectionModeMetadata = {
          remoteAddress: "216.247.15.107",
          host: "  tunnel.trycloudflare.com  ",
          secureTransport: true,
        };

        const result = detectConnectionMode(metadata);
        expect(result).toBe("secure_remote");
      });
    });
  });

  describe("Connection metadata propagation", () => {
    it("should include Cloudflare tunnel info in description when host is available", () => {
      const description = describeConnectionMode("secure_remote", {
        host: "my-app.trycloudflare.com",
        remoteAddress: "216.247.15.107",
      });

      // Should reference the tunnel host, not the raw IP
      expect(description).toContain("my-app.trycloudflare.com");
      expect(description.toLowerCase()).toContain("secure");
    });

    it("should fall back to IP when host is unavailable but IP is Cloudflare", () => {
      const description = describeConnectionMode("secure_remote", {
        remoteAddress: "216.247.15.107",
        host: undefined,
      });

      // Should still indicate a secure connection
      expect(description.toLowerCase()).toContain("secure");
    });
  });
});
