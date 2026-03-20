import fs from "fs";
import path from "path";
import { promisify } from "util";

const readdirAsync = promisify(fs.readdir);
const statAsync = promisify(fs.stat);
const readFileAsync = promisify(fs.readFile);

export interface FileEntry {
  name: string;
  type: "file" | "directory";
  size?: number;
  modifiedAt?: string;
}

export interface FileListResult {
  entries: FileEntry[];
  total: number;
  offset: number;
  limit: number;
  hasMore: boolean;
}

export interface FileReadResult {
  content: string;
  totalLines: number;
  offset: number;
  limit: number;
  hasMore: boolean;
}

const DEFAULT_LIST_LIMIT = 100;
const DEFAULT_READ_LIMIT = 500;

export class FileService {
  constructor(private allowedRoot: string) {}

  async listDirectory(
    dirPath: string,
    options: {
      offset?: number;
      limit?: number;
      includeHidden?: boolean;
    } = {},
  ): Promise<FileListResult> {
    const resolved = path.resolve(dirPath);
    this.validatePath(resolved);

    const { offset = 0, limit = DEFAULT_LIST_LIMIT, includeHidden = false } = options;

    const names = await readdirAsync(resolved);

    const allEntries: FileEntry[] = [];
    for (const name of names) {
      if (!includeHidden && name.startsWith(".")) {
        continue;
      }
      const full = path.join(resolved, name);
      try {
        const stat = await statAsync(full);
        allEntries.push({
          name,
          type: stat.isDirectory() ? "directory" : "file",
          size: stat.isFile() ? stat.size : undefined,
          modifiedAt: stat.mtime.toISOString(),
        });
      } catch {
        allEntries.push({ name, type: "file" });
      }
    }

    // Sort: directories first, then files, both alphabetically
    allEntries.sort((a, b) => {
      if (a.type === b.type) {
        return a.name.localeCompare(b.name);
      }
      return a.type === "directory" ? -1 : 1;
    });

    const total = allEntries.length;
    const page = allEntries.slice(offset, offset + limit);

    return {
      entries: page,
      total,
      offset,
      limit,
      hasMore: offset + limit < total,
    };
  }

  async readFile(
    filePath: string,
    options: {
      offset?: number;
      limit?: number;
    } = {},
  ): Promise<FileReadResult> {
    const resolved = path.resolve(filePath);
    this.validatePath(resolved);

    const { offset = 0, limit = DEFAULT_READ_LIMIT } = options;

    const raw = await readFileAsync(resolved, "utf8");
    const allLines = raw.split("\n");
    const totalLines = allLines.length;

    const page = allLines.slice(offset, offset + limit);

    return {
      content: page.join("\n"),
      totalLines,
      offset,
      limit,
      hasMore: offset + limit < totalLines,
    };
  }

  private validatePath(p: string): void {
    const resolvedRoot = path.resolve(this.allowedRoot);
    if (!p.startsWith(resolvedRoot + path.sep) && p !== resolvedRoot) {
      throw new Error(`Access denied: path "${p}" is outside the allowed root "${resolvedRoot}"`);
    }
  }
}
