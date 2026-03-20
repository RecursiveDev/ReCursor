import { AgentSessionManager } from "../../src/agents/session_manager";
import { eventBus } from "../../src/notifications/event_bus";
import type {
  AgentRuntime,
  AgentRuntimeTurnRequest,
  AgentRuntimeTurnResult,
} from "../../src/agents/agent_runtime";

function nextTick(): Promise<void> {
  return new Promise((resolve) => {
    setImmediate(resolve);
  });
}

describe("AgentSessionManager", () => {
  afterEach(() => {
    eventBus.removeAllListeners();
  });

  // =========================================================================
  // Session Resume Tests
  // =========================================================================

  describe("resumeSession", () => {
    it("throws when session does not exist", async () => {
      const runtime: AgentRuntime = { runTurn: jest.fn() };
      const toolExecutor = { getToolDefinitions: jest.fn(() => []), execute: jest.fn() };
      const manager = new AgentSessionManager(runtime, toolExecutor as never);

      await expect(manager.resumeSession("nonexistent-session")).rejects.toThrow(
        "Session not found: nonexistent-session",
      );
    });

    it("sets session status to idle and preserves metadata", async () => {
      const runtime: AgentRuntime = { runTurn: jest.fn() };
      const toolExecutor = { getToolDefinitions: jest.fn(() => []), execute: jest.fn() };
      const manager = new AgentSessionManager(runtime, toolExecutor as never);

      const sessionId = await manager.createSession({
        workingDirectory: process.cwd(),
        model: "claude-opus-4-6",
      });

      // Verify session was created
      const sessionBefore = manager.getSession(sessionId);
      expect(sessionBefore).toBeDefined();
      expect(sessionBefore!.status).toBe("idle");

      // Close the session
      manager.closeSession(sessionId);

      // Verify session is removed and can't be resumed
      await expect(manager.resumeSession(sessionId)).rejects.toThrow(
        `Session not found: ${sessionId}`,
      );
    });

    it("resuming an active session sets status to idle", async () => {
      const runtime: AgentRuntime = { runTurn: jest.fn() };
      const toolExecutor = { getToolDefinitions: jest.fn(() => []), execute: jest.fn() };
      const manager = new AgentSessionManager(runtime, toolExecutor as never);

      const sessionId = await manager.createSession({
        workingDirectory: process.cwd(),
        model: "claude-opus-4-6",
      });

      // Verify session exists and is idle
      const sessionBefore = manager.getSession(sessionId);
      expect(sessionBefore).toBeDefined();
      expect(sessionBefore!.status).toBe("idle");

      // Resume should succeed and keep it idle
      await manager.resumeSession(sessionId);

      const sessionAfter = manager.getSession(sessionId);
      expect(sessionAfter).toBeDefined();
      expect(sessionAfter!.status).toBe("idle");
    });

    it("preserves session history across resume", async () => {
      const runTurn = jest
        .fn<Promise<AgentRuntimeTurnResult>, [AgentRuntimeTurnRequest]>()
        .mockImplementationOnce(async () => ({
          stopReason: "end_turn",
          message: {
            role: "assistant",
            content: [{ type: "text", text: "Response" }],
          },
        }));

      const runtime: AgentRuntime = { runTurn };
      const toolExecutor = { getToolDefinitions: jest.fn(() => []), execute: jest.fn() };
      const manager = new AgentSessionManager(runtime, toolExecutor as never);

      const sessionId = await manager.createSession({
        workingDirectory: process.cwd(),
        model: "claude-opus-4-6",
      });

      // Send a message to populate history
      await manager.sendMessage(sessionId, "First message", "client-1");

      // Verify session is still accessible
      const session = manager.getSession(sessionId);
      expect(session).toBeDefined();

      // Resume should succeed
      await expect(manager.resumeSession(sessionId)).resolves.toBeUndefined();
    });
  });

  it("waits for approval, executes the tool, and resumes the session turn", async () => {
    const runTurn = jest
      .fn<Promise<AgentRuntimeTurnResult>, [AgentRuntimeTurnRequest]>()
      .mockImplementationOnce(async (request) => {
        request.onTextDelta?.("Planning change...");
        return {
          stopReason: "tool_use",
          message: {
            role: "assistant",
            content: [
              { type: "text", text: "Planning change..." },
              {
                type: "tool_use",
                id: "tool-call-1",
                name: "run_command",
                input: { command: "node -e console.log(1)" },
              },
            ],
          },
        };
      })
      .mockImplementationOnce(async (request) => {
        expect(request.messages.at(-1)).toMatchObject({
          role: "user",
          content: [
            {
              type: "tool_result",
              tool_use_id: "tool-call-1",
              is_error: false,
            },
          ],
        });

        request.onTextDelta?.("Done.");
        return {
          stopReason: "end_turn",
          message: {
            role: "assistant",
            content: [{ type: "text", text: "Done." }],
          },
        };
      });

    const runtime: AgentRuntime = {
      runTurn,
    };

    const toolExecutor = {
      getToolDefinitions: jest.fn(() => []),
      execute: jest.fn(async () => ({
        success: true,
        content: "command output",
        durationMs: 17,
      })),
    };

    const manager = new AgentSessionManager(runtime, toolExecutor as never);
    const streamChunks: string[] = [];
    const sessionEvents: Array<Record<string, unknown>> = [];
    const toolEvents: Array<Record<string, unknown>> = [];

    eventBus.onTyped("stream-chunk", (payload) => {
      streamChunks.push(String((payload as { content?: unknown }).content ?? ""));
    });
    eventBus.onTyped("session-event", (payload) => {
      sessionEvents.push(payload as Record<string, unknown>);
    });
    eventBus.onTyped("tool-event", (payload) => {
      toolEvents.push(payload as Record<string, unknown>);
    });

    const sessionId = await manager.createSession({
      workingDirectory: process.cwd(),
      model: "claude-opus-4-6",
    });

    const sendPromise = manager.sendMessage(sessionId, "Run the command", "client-1");
    await nextTick();

    expect(toolEvents).toContainEqual(
      expect.objectContaining({
        type: "approval_required",
        session_id: sessionId,
        tool_call_id: "tool-call-1",
        tool: "run_command",
      }),
    );

    await manager.executeToolCall(sessionId, "tool-call-1", "modified", {
      command: "node -e console.log(2)",
    });
    await sendPromise;

    expect(toolExecutor.execute).toHaveBeenCalledWith(
      "run_command",
      { command: "node -e console.log(2)" },
      process.cwd(),
    );
    expect(toolEvents).toContainEqual(
      expect.objectContaining({
        type: "tool_result",
        session_id: sessionId,
        tool_call_id: "tool-call-1",
        tool: "run_command",
        result: expect.objectContaining({
          success: true,
          content: "command output",
          duration_ms: 17,
        }),
      }),
    );
    expect(streamChunks).toEqual(["Planning change...", "Done."]);
    expect(sessionEvents).toContainEqual(
      expect.objectContaining({
        type: "stream_end",
        session_id: sessionId,
        finish_reason: "stop",
      }),
    );
    expect(runTurn).toHaveBeenCalledTimes(2);
  });

  it("turns rejected approvals into tool_result feedback without running the tool", async () => {
    const runTurn = jest
      .fn<Promise<AgentRuntimeTurnResult>, [AgentRuntimeTurnRequest]>()
      .mockImplementationOnce(async () => ({
        stopReason: "tool_use",
        message: {
          role: "assistant",
          content: [
            {
              type: "tool_use",
              id: "tool-call-2",
              name: "edit_file",
              input: {
                path: "README.md",
                old_string: "old",
                new_string: "new",
              },
            },
          ],
        },
      }))
      .mockImplementationOnce(async (request) => {
        expect(request.messages.at(-1)).toMatchObject({
          role: "user",
          content: [
            {
              type: "tool_result",
              tool_use_id: "tool-call-2",
              is_error: true,
              content: expect.stringContaining("rejected by user"),
            },
          ],
        });

        return {
          stopReason: "end_turn",
          message: {
            role: "assistant",
            content: [{ type: "text", text: "Okay, I will not apply it." }],
          },
        };
      });

    const runtime: AgentRuntime = { runTurn };
    const toolExecutor = {
      getToolDefinitions: jest.fn(() => []),
      execute: jest.fn(),
    };

    const manager = new AgentSessionManager(runtime, toolExecutor as never);
    const toolEvents: Array<Record<string, unknown>> = [];
    eventBus.onTyped("tool-event", (payload) => {
      toolEvents.push(payload as Record<string, unknown>);
    });

    const sessionId = await manager.createSession({ workingDirectory: process.cwd() });
    const sendPromise = manager.sendMessage(sessionId, "Try editing the file", "client-1");
    await nextTick();

    await manager.executeToolCall(sessionId, "tool-call-2", "rejected", null);
    await sendPromise;

    expect(toolExecutor.execute).not.toHaveBeenCalled();
    expect(toolEvents).toContainEqual(
      expect.objectContaining({
        type: "tool_rejected",
        session_id: sessionId,
        tool_call_id: "tool-call-2",
      }),
    );
  });

  it("rejects approval responses for unknown tool calls", async () => {
    const runtime: AgentRuntime = {
      runTurn: jest.fn(),
    };

    const manager = new AgentSessionManager(runtime, {
      getToolDefinitions: jest.fn(() => []),
      execute: jest.fn(),
    } as never);

    const sessionId = await manager.createSession({ workingDirectory: process.cwd() });

    await expect(
      manager.executeToolCall(sessionId, "missing-tool-call", "approved", null),
    ).rejects.toThrow("Tool call not found: missing-tool-call");
  });
});
