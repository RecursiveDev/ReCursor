import { EventEmitter } from "events";
import type { Readable } from "stream";

export class TerminalOutputStream extends EventEmitter {
  private buffer: string[] = [];
  private closed = false;

  constructor(readable?: Readable) {
    super();
    if (readable) {
      readable.on("data", (chunk: Buffer | string) => {
        this.write(chunk.toString());
      });
      readable.on("end", () => {
        this.close();
      });
    }
  }

  write(data: string): void {
    if (this.closed) return;
    this.buffer.push(data);
    this.emit("data", data);
  }

  close(): void {
    if (this.closed) return;
    this.closed = true;
    this.emit("close");
  }

  getBuffer(): string {
    return this.buffer.join("");
  }

  isClosed(): boolean {
    return this.closed;
  }
}
