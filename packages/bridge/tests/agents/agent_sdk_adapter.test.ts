import { AgentSdkAdapter } from "../../src/agents/agent_sdk_adapter";
import type { ConnectionManager } from "../../src/websocket/connection_manager";
import type { BridgeMessage } from "../../src/types";

describe("AgentSdkAdapter", () => {
  describe("handleSessionStart - resume behavior", () => {
    function createMockDependencies() {
      const sentMessages: Array<{ clientId: string; message: BridgeMessage }> = [];

      const connectionManager = {
        sendToClient: jest.fn((clientId: string, message: BridgeMessage) => {
          sentMessages.push({ clientId, message });
        }),
        addSessionToClient: jest.fn(),
      };

      const sessionManager = {
        createSession: jest.fn<Promise<string>, [unknown]>(),
        resumeSession: jest.fn<Promise<void>, [string]>(),
        getSession: jest.fn(),
        closeSession: jest.fn(),
      };

      return {
        connectionManager: connectionManager as unknown as ConnectionManager,
        sessionManager,
        sentMessages,
      };
    }

    it("creates a new session when resume is false", async () => {
      const { connectionManager, sessionManager, sentMessages } = createMockDependencies();

      sessionManager.createSession.mockResolvedValue("new-session-id");
      sessionManager.getSession.mockReturnValue({
        id: "new-session-id",
        agent: "claude-code",
        title: "project",
        model: "claude-opus-4-6",
        working_directory: "/repo/project",
        created_at: new Date().toISOString(),
        status: "idle",
      });

      const adapter = new AgentSdkAdapter(sessionManager as never, connectionManager as never);

      await adapter.handleSessionStart(
        {
          agent: "claude-code",
          working_directory: "/repo/project",
          resume: false,
        },
        "client-1",
        "req-123",
      );

      expect(sessionManager.createSession).toHaveBeenCalledWith(
        expect.objectContaining({
          agent: "claude-code",
          workingDirectory: "/repo/project",
        }),
      );
      expect(sessionManager.resumeSession).not.toHaveBeenCalled();
      expect(connectionManager.addSessionToClient).toHaveBeenCalledWith(
        "client-1",
        "new-session-id",
      );

      expect(sentMessages[0]?.message).toMatchObject({
        type: "session_ready",
        id: "req-123",
        payload: {
          session_id: "new-session-id",
          agent: "claude-code",
          working_directory: "/repo/project",
          status: "ready",
        },
      });
    });

    it("creates a new session when resume is true but session_id is missing", async () => {
      const { connectionManager, sessionManager, sentMessages } = createMockDependencies();

      sessionManager.createSession.mockResolvedValue("new-session-id");
      sessionManager.getSession.mockReturnValue({
        id: "new-session-id",
        agent: "claude-code",
        title: "project",
        model: "claude-opus-4-6",
        working_directory: "/repo/project",
        created_at: new Date().toISOString(),
        status: "idle",
      });

      const adapter = new AgentSdkAdapter(sessionManager as never, connectionManager as never);

      // resume: true but no session_id provided
      await adapter.handleSessionStart(
        {
          agent: "claude-code",
          working_directory: "/repo/project",
          resume: true,
          // session_id is undefined/null
        },
        "client-1",
        "req-123",
      );

      // Should create a new session since session_id is not a valid string
      expect(sessionManager.createSession).toHaveBeenCalled();
      expect(sessionManager.resumeSession).not.toHaveBeenCalled();
    });

    it("resumes existing session when resume is true and session_id is provided", async () => {
      const { connectionManager, sessionManager, sentMessages } = createMockDependencies();

      sessionManager.resumeSession.mockResolvedValue(undefined);
      sessionManager.getSession.mockReturnValue({
        id: "existing-session-id",
        agent: "claude-code",
        title: "resumed-project",
        model: "claude-opus-4-6",
        working_directory: "/repo/resumed",
        created_at: new Date().toISOString(),
        status: "idle",
      });

      const adapter = new AgentSdkAdapter(sessionManager as never, connectionManager as never);

      await adapter.handleSessionStart(
        {
          agent: "claude-code",
          session_id: "existing-session-id",
          working_directory: "/repo/resumed",
          resume: true,
        },
        "client-1",
        "req-resume-1",
      );

      expect(sessionManager.resumeSession).toHaveBeenCalledWith("existing-session-id");
      expect(sessionManager.createSession).not.toHaveBeenCalled();
      expect(connectionManager.addSessionToClient).toHaveBeenCalledWith(
        "client-1",
        "existing-session-id",
      );

      expect(sentMessages[0]?.message).toMatchObject({
        type: "session_ready",
        id: "req-resume-1",
        payload: {
          session_id: "existing-session-id",
          agent: "claude-code",
          working_directory: "/repo/resumed",
          status: "ready",
        },
      });
    });

    it("sends error when resume fails for non-existent session", async () => {
      const { connectionManager, sessionManager, sentMessages } = createMockDependencies();

      sessionManager.resumeSession.mockRejectedValue(
        new Error("Session not found: nonexistent-id"),
      );

      const adapter = new AgentSdkAdapter(sessionManager as never, connectionManager as never);

      await adapter.handleSessionStart(
        {
          agent: "claude-code",
          session_id: "nonexistent-id",
          resume: true,
        },
        "client-1",
        "req-resume-fail",
      );

      expect(sessionManager.resumeSession).toHaveBeenCalledWith("nonexistent-id");
      expect(connectionManager.addSessionToClient).not.toHaveBeenCalled();

      expect(sentMessages[0]?.message).toMatchObject({
        type: "error",
        id: "req-resume-fail",
        payload: {
          code: "BRIDGE_ERROR",
          message: expect.stringContaining("Session not found"),
          request_type: "session_start",
          recoverable: false,
        },
      });
    });

    it("sends error when session not found after resume", async () => {
      const { connectionManager, sessionManager, sentMessages } = createMockDependencies();

      // Resume succeeds but session isn't found after (edge case)
      sessionManager.resumeSession.mockResolvedValue(undefined);
      sessionManager.getSession.mockReturnValue(undefined);

      const adapter = new AgentSdkAdapter(sessionManager as never, connectionManager as never);

      await adapter.handleSessionStart(
        {
          agent: "claude-code",
          session_id: "ghost-session-id",
          resume: true,
        },
        "client-1",
        "req-ghost",
      );

      expect(sentMessages[0]?.message).toMatchObject({
        type: "error",
        payload: {
          code: "BRIDGE_ERROR",
          message: expect.stringContaining("Session not found after start"),
          request_type: "session_start",
        },
      });
    });
  });
});
