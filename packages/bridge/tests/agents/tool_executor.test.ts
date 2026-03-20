import fs from "fs";
import path from "path";
import { ToolExecutor } from "../../src/agents/tool_executor";

describe("ToolExecutor", () => {
  let tempDir: string;

  beforeEach(() => {
    tempDir = fs.mkdtempSync(path.join(process.cwd(), "tool-executor-"));
    fs.writeFileSync(path.join(tempDir, "sample.txt"), "hello world\n", "utf8");
  });

  afterEach(() => {
    fs.rmSync(tempDir, { recursive: true, force: true });
  });

  it("supports Agent SDK style aliases and protocol tool names", async () => {
    const executor = new ToolExecutor();

    const readResult = await executor.execute("Read", { path: "sample.txt" }, tempDir);
    const lsResult = await executor.execute("ls", { path: "." }, tempDir);
    const commandResult = await executor.execute(
      "Bash",
      { command: "denied_command --flag" },
      tempDir,
    );

    expect(readResult).toMatchObject({
      success: true,
      content: "hello world\n",
    });
    expect(lsResult).toMatchObject({
      success: true,
      content: expect.stringContaining("file\tsample.txt"),
    });
    expect(commandResult).toMatchObject({
      success: false,
      error: expect.stringContaining("Command not allowed: denied_command"),
    });
  });

  it("runs allowlisted protocol commands within the working directory", async () => {
    const executor = new ToolExecutor();
    const commandResult = await executor.execute(
      "run_command",
      { command: "node -e console.log(process.cwd())" },
      tempDir,
    );

    expect(commandResult.success).toBe(true);
    expect(commandResult.content.trim()).toBe(tempDir);
  });
});
