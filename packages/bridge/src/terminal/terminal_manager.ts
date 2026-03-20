import { spawn, type ChildProcess } from "child_process";
import os from "os";
import { v4 as uuidv4 } from "uuid";
import { TerminalOutputStream } from "./output_stream";
import { eventBus } from "../notifications/event_bus";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [TerminalManager] ${msg}`);
}

export interface TerminalSession {
  id: string;
  workingDirectory: string;
  process: ChildProcess;
  outputStream: TerminalOutputStream;
  createdAt: string;
}

export class TerminalManager {
  private sessions = new Map<string, TerminalSession>();

  createSession(id: string, workingDirectory: string): TerminalSession {
    const shell = os.platform() === "win32" ? "cmd.exe" : "/bin/sh";
    const args = os.platform() === "win32" ? [] : [];

    const proc = spawn(shell, args, {
      cwd: workingDirectory,
      env: process.env,
      stdio: ["pipe", "pipe", "pipe"],
    });

    const outputStream = new TerminalOutputStream();

    proc.stdout?.on("data", (chunk: Buffer) => {
      const data = chunk.toString();
      outputStream.write(data);
      this.forwardOutput(id, data);
    });

    proc.stderr?.on("data", (chunk: Buffer) => {
      const data = chunk.toString();
      outputStream.write(data);
      this.forwardOutput(id, data);
    });

    proc.on("close", (code) => {
      log(`Session ${id} exited with code ${code}`);
      outputStream.close();
      eventBus.emitTyped("session-event", {
        type: "terminal_exit",
        session_id: id,
        exit_code: code,
      });
    });

    const session: TerminalSession = {
      id,
      workingDirectory,
      process: proc,
      outputStream,
      createdAt: new Date().toISOString(),
    };

    this.sessions.set(id, session);
    log(`Created terminal session: ${id} (cwd=${workingDirectory})`);
    return session;
  }

  getSession(id: string): TerminalSession | undefined {
    return this.sessions.get(id);
  }

  closeSession(id: string): void {
    const session = this.sessions.get(id);
    if (!session) return;
    try {
      session.process.kill();
    } catch (_) {
      // already dead
    }
    session.outputStream.close();
    this.sessions.delete(id);
    log(`Closed terminal session: ${id}`);
  }

  sendInput(id: string, data: string): void {
    const session = this.sessions.get(id);
    if (!session) {
      log(`sendInput: session not found: ${id}`);
      return;
    }
    session.process.stdin?.write(data);
  }

  private forwardOutput(sessionId: string, data: string): void {
    eventBus.emitTyped("tool-event", {
      type: "terminal_output",
      session_id: sessionId,
      data,
    });
  }
}
