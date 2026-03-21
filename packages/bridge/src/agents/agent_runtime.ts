import Anthropic from "@anthropic-ai/sdk";

export interface AgentToolDefinition {
  name: string;
  description: string;
  inputSchema: Anthropic.Tool["input_schema"];
}

export interface AgentRuntimeTextBlock {
  type: "text";
  text: string;
}

export interface AgentRuntimeToolUseBlock {
  type: "tool_use";
  id: string;
  name: string;
  input: Record<string, unknown>;
}

export interface AgentRuntimeToolResultBlock {
  type: "tool_result";
  tool_use_id: string;
  content: string;
  is_error?: boolean;
}

export type AgentRuntimeMessageContentBlock =
  | AgentRuntimeTextBlock
  | AgentRuntimeToolUseBlock
  | AgentRuntimeToolResultBlock;

export interface AgentRuntimeMessage {
  role: "user" | "assistant";
  content: string | AgentRuntimeMessageContentBlock[];
}

export interface AgentRuntimeTurnRequest {
  model: string;
  maxTokens: number;
  messages: AgentRuntimeMessage[];
  systemPrompt?: string;
  tools?: AgentToolDefinition[];
  onTextDelta?: (text: string) => void;
}

export interface AgentRuntimeTurnResult {
  stopReason: string | null;
  message: {
    role: "assistant";
    content: Array<AgentRuntimeTextBlock | AgentRuntimeToolUseBlock>;
  };
}

export interface AgentRuntime {
  runTurn(request: AgentRuntimeTurnRequest): Promise<AgentRuntimeTurnResult>;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

export class DisabledAgentRuntime implements AgentRuntime {
  constructor(private readonly reason: string) {}

  async runTurn(_request: AgentRuntimeTurnRequest): Promise<AgentRuntimeTurnResult> {
    throw new Error(this.reason);
  }
}

export class AnthropicMessageRuntime implements AgentRuntime {
  constructor(private client: Anthropic) {}

  async runTurn(request: AgentRuntimeTurnRequest): Promise<AgentRuntimeTurnResult> {
    const streamParams: Anthropic.MessageStreamParams = {
      model: request.model,
      max_tokens: request.maxTokens,
      messages: request.messages.map((message) => this.toAnthropicMessage(message)),
      stream: true,
    };

    if (request.systemPrompt) {
      (streamParams as Record<string, unknown>).system = request.systemPrompt;
    }

    if (request.tools && request.tools.length > 0) {
      (streamParams as Record<string, unknown>).tools = request.tools.map((tool) => ({
        name: tool.name,
        description: tool.description,
        input_schema: tool.inputSchema,
      }));
    }

    const stream = this.client.messages.stream(streamParams);
    if (request.onTextDelta) {
      stream.on("text", (textDelta) => {
        request.onTextDelta?.(textDelta);
      });
    }

    const finalMessage = await stream.finalMessage();

    return {
      stopReason: finalMessage.stop_reason,
      message: {
        role: "assistant",
        content: finalMessage.content.flatMap((block) => {
          const normalized = this.fromAnthropicContentBlock(block);
          return normalized ? [normalized] : [];
        }),
      },
    };
  }

  private toAnthropicMessage(message: AgentRuntimeMessage): Anthropic.MessageParam {
    const content =
      typeof message.content === "string"
        ? message.content
        : message.content.map((block) => this.toAnthropicContentBlock(block));

    return {
      role: message.role,
      content,
    };
  }

  private toAnthropicContentBlock(block: AgentRuntimeMessageContentBlock) {
    switch (block.type) {
      case "text":
        return {
          type: "text" as const,
          text: block.text,
        };
      case "tool_use":
        return {
          type: "tool_use" as const,
          id: block.id,
          name: block.name,
          input: block.input,
        };
      case "tool_result":
        return {
          type: "tool_result" as const,
          tool_use_id: block.tool_use_id,
          content: block.content,
          is_error: block.is_error,
        };
    }
  }

  private fromAnthropicContentBlock(
    block: Anthropic.ContentBlock,
  ): AgentRuntimeTextBlock | AgentRuntimeToolUseBlock | null {
    if (block.type === "text") {
      return {
        type: "text",
        text: block.text,
      };
    }

    if (block.type === "tool_use") {
      return {
        type: "tool_use",
        id: block.id,
        name: block.name,
        input: isRecord(block.input) ? block.input : {},
      };
    }

    return null;
  }
}
