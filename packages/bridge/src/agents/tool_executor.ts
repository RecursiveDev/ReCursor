import fs from "fs";
import path from "path";
import { spawn } from "child_process";
import { promisify } from "util";
import { config } from "../config";
import type { ToolResult } from "../types";

const readFileAsync = promisify(fs.readFile);
const writeFileAsync = promisify(fs.writeFile);
const readdirAsync = promisify(fs.readdir);
const statAsync = promisify(fs.stat);

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [ToolExecutor] ${msg}`);
}

const ALLOWED_COMMANDS = ["git", "flutter", "npm", "node", "dart"];

function isWithinAllowedRoot(filePath: string): boolean {
  const resolved = path.resolve(filePath);
  const allowed = path.resolve(config.ALLOWED_PROJECT_ROOT);
  return resolved.startsWith(allowed + path.sep) || resolved === allowed;
}

function resolveWithinRoot(filePath: string, workingDir: string): string {
  const resolved = path.isAbsolute(filePath)
    ? path.resolve(filePath)
    : path.resolve(workingDir, filePath);
  return resolved;
}

export class ToolExecutor {
  async execute(
    tool: string,
    params: Record<string, unknown>,
    workingDir: string
  ): Promise<ToolResult> {
    const start = Date.now();

    if (!isWithinAllowedRoot(workingDir)) {
      return {
        success: false,
        content: "",
        error: `Working directory is outside of allowed project root: ${workingDir}`,
        durationMs: Date.now() - start,
      };
    }

    try {
      let result: ToolResult;
      switch (tool) {
        case "read_file":
          result = await this.readFile(params, workingDir, start);
          break;
        case "edit_file":
          result = await this.editFile(params, workingDir, start);
          break;
        case "bash_command":
          result = await this.bashCommand(params, workingDir, start);
          break;
        case "glob":
          result = await this.glob(params, workingDir, start);
          break;
        case "grep":
          result = await this.grep(params, workingDir, start);
          break;
        case "list_files":
          result = await this.listFiles(params, workingDir, start);
          break;
        default:
          result = {
            success: false,
            content: "",
            error: `Unknown tool: ${tool}`,
            durationMs: Date.now() - start,
          };
      }
      return result;
    } catch (err) {
      return {
        success: false,
        content: "",
        error: String(err),
        durationMs: Date.now() - start,
      };
    }
  }

  private async readFile(
    params: Record<string, unknown>,
    workingDir: string,
    start: number
  ): Promise<ToolResult> {
    const filePath = String(params["path"] ?? "");
    const resolved = resolveWithinRoot(filePath, workingDir);

    if (!isWithinAllowedRoot(resolved)) {
      return { success: false, content: "", error: "Path outside allowed root", durationMs: Date.now() - start };
    }

    const content = await readFileAsync(resolved, "utf8");
    return { success: true, content, durationMs: Date.now() - start };
  }

  private async editFile(
    params: Record<string, unknown>,
    workingDir: string,
    start: number
  ): Promise<ToolResult> {
    const filePath = String(params["path"] ?? "");
    const oldStr = String(params["old_string"] ?? "");
    const newStr = String(params["new_string"] ?? "");
    const resolved = resolveWithinRoot(filePath, workingDir);

    if (!isWithinAllowedRoot(resolved)) {
      return { success: false, content: "", error: "Path outside allowed root", durationMs: Date.now() - start };
    }

    const original = await readFileAsync(resolved, "utf8");
    if (!original.includes(oldStr)) {
      return { success: false, content: "", error: "old_string not found in file", durationMs: Date.now() - start };
    }

    const updated = original.replace(oldStr, newStr);
    await writeFileAsync(resolved, updated, "utf8");
    return { success: true, content: "File updated successfully", durationMs: Date.now() - start };
  }

  private bashCommand(
    params: Record<string, unknown>,
    workingDir: string,
    start: number
  ): Promise<ToolResult> {
    return new Promise((resolve) => {
      const command = String(params["command"] ?? "");
      const parts = command.trim().split(/\s+/);
      const executable = parts[0];

      if (!ALLOWED_COMMANDS.includes(executable)) {
        resolve({
          success: false,
          content: "",
          error: `Command not allowed: ${executable}. Allowed: ${ALLOWED_COMMANDS.join(", ")}`,
          durationMs: Date.now() - start,
        });
        return;
      }

      const child = spawn(executable, parts.slice(1), {
        cwd: workingDir,
        env: process.env,
        shell: false,
      });

      let stdout = "";
      let stderr = "";

      child.stdout.on("data", (d: Buffer) => { stdout += d.toString(); });
      child.stderr.on("data", (d: Buffer) => { stderr += d.toString(); });

      child.on("close", (code) => {
        const success = code === 0;
        resolve({
          success,
          content: stdout,
          error: success ? undefined : stderr || `Exit code: ${code}`,
          durationMs: Date.now() - start,
        });
      });

      child.on("error", (err) => {
        resolve({
          success: false,
          content: "",
          error: String(err),
          durationMs: Date.now() - start,
        });
      });
    });
  }

  private async glob(
    params: Record<string, unknown>,
    workingDir: string,
    start: number
  ): Promise<ToolResult> {
    const pattern = String(params["pattern"] ?? "**/*");
    const baseDir = resolveWithinRoot(
      String(params["base_dir"] ?? "."),
      workingDir
    );

    if (!isWithinAllowedRoot(baseDir)) {
      return { success: false, content: "", error: "Path outside allowed root", durationMs: Date.now() - start };
    }

    // Use native fs walk for glob
    const results: string[] = [];
    await this.walkGlob(baseDir, baseDir, pattern, results);
    return { success: true, content: results.join("\n"), durationMs: Date.now() - start };
  }

  private async walkGlob(
    base: string,
    current: string,
    pattern: string,
    results: string[]
  ): Promise<void> {
    let entries: string[];
    try {
      entries = await readdirAsync(current);
    } catch {
      return;
    }

    for (const entry of entries) {
      const full = path.join(current, entry);
      const rel = path.relative(base, full);

      let stat;
      try {
        stat = await statAsync(full);
      } catch {
        continue;
      }

      if (stat.isDirectory()) {
        await this.walkGlob(base, full, pattern, results);
      } else {
        // Simple glob: support * and **
        if (this.matchGlob(rel, pattern)) {
          results.push(rel);
        }
      }
    }
  }

  private matchGlob(filePath: string, pattern: string): boolean {
    const regexStr = pattern
      .replace(/\./g, "\\.")
      .replace(/\*\*/g, "DOUBLESTAR")
      .replace(/\*/g, "[^/]*")
      .replace(/DOUBLESTAR/g, ".*");
    const regex = new RegExp(`^${regexStr}$`);
    return regex.test(filePath);
  }

  private async grep(
    params: Record<string, unknown>,
    workingDir: string,
    start: number
  ): Promise<ToolResult> {
    const searchPattern = String(params["pattern"] ?? "");
    const searchPath = resolveWithinRoot(
      String(params["path"] ?? "."),
      workingDir
    );

    if (!isWithinAllowedRoot(searchPath)) {
      return { success: false, content: "", error: "Path outside allowed root", durationMs: Date.now() - start };
    }

    const results: string[] = [];
    await this.grepDirectory(searchPath, searchPattern, results);
    return { success: true, content: results.join("\n"), durationMs: Date.now() - start };
  }

  private async grepDirectory(
    searchPath: string,
    pattern: string,
    results: string[]
  ): Promise<void> {
    let stat;
    try {
      stat = await statAsync(searchPath);
    } catch {
      return;
    }

    if (stat.isFile()) {
      await this.grepFile(searchPath, pattern, results);
      return;
    }

    if (stat.isDirectory()) {
      let entries: string[];
      try {
        entries = await readdirAsync(searchPath);
      } catch {
        return;
      }
      for (const entry of entries) {
        await this.grepDirectory(path.join(searchPath, entry), pattern, results);
      }
    }
  }

  private async grepFile(
    filePath: string,
    pattern: string,
    results: string[]
  ): Promise<void> {
    let content: string;
    try {
      content = await readFileAsync(filePath, "utf8");
    } catch {
      return;
    }

    const regex = new RegExp(pattern, "gm");
    const lines = content.split("\n");
    lines.forEach((line, i) => {
      if (regex.test(line)) {
        results.push(`${filePath}:${i + 1}: ${line}`);
      }
      regex.lastIndex = 0;
    });
  }

  private async listFiles(
    params: Record<string, unknown>,
    workingDir: string,
    start: number
  ): Promise<ToolResult> {
    const dirPath = resolveWithinRoot(
      String(params["path"] ?? "."),
      workingDir
    );

    if (!isWithinAllowedRoot(dirPath)) {
      return { success: false, content: "", error: "Path outside allowed root", durationMs: Date.now() - start };
    }

    const entries = await readdirAsync(dirPath);
    const details: string[] = [];

    for (const entry of entries) {
      const full = path.join(dirPath, entry);
      try {
        const stat = await statAsync(full);
        const type = stat.isDirectory() ? "dir" : "file";
        details.push(`${type}\t${entry}`);
      } catch {
        details.push(`unknown\t${entry}`);
      }
    }

    return { success: true, content: details.join("\n"), durationMs: Date.now() - start };
  }
}
