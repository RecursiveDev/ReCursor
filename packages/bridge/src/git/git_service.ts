import simpleGit, { type SimpleGit, type StatusResult } from "simple-git";
import { parseDiff } from "./diff_parser";
import type { GitStatusPayload, GitFileChange, DiffFile, GitBranch } from "../types";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [GitService] ${msg}`);
}

function mapStatusCode(code: string, staged: boolean): GitFileChange["status"] {
  switch (code) {
    case "A":
      return "added";
    case "M":
      return "modified";
    case "D":
      return "deleted";
    case "R":
      return "renamed";
    case "C":
      return "copied";
    case "?":
      return "untracked";
    default:
      return "unknown";
  }
}

export class GitService {
  private git: SimpleGit;
  private workingDirectory: string;

  constructor(workingDirectory: string) {
    this.workingDirectory = workingDirectory;
    this.git = simpleGit(workingDirectory);
  }

  async getStatus(): Promise<GitStatusPayload> {
    const status: StatusResult = await this.git.status();

    const changes: GitFileChange[] = [];

    for (const f of status.files) {
      const isStaged = f.index !== " " && f.index !== "?";
      changes.push({
        path: f.path,
        status: mapStatusCode(isStaged ? f.index : f.working_dir, isStaged),
        staged: isStaged,
      });
    }

    return {
      branch: status.current ?? "HEAD",
      ahead: status.ahead,
      behind: status.behind,
      is_clean: status.isClean(),
      changes,
    };
  }

  async getDiff(files?: string[], cached?: boolean): Promise<DiffFile[]> {
    const args: string[] = [];
    if (cached) args.push("--cached");
    if (files && files.length > 0) {
      args.push("--");
      args.push(...files);
    }

    const rawDiff = await this.git.diff(args);
    return parseDiff(rawDiff);
  }

  async commit(message: string, files?: string[]): Promise<void> {
    if (files && files.length > 0) {
      await this.git.add(files);
    } else {
      await this.git.add(".");
    }
    await this.git.commit(message);
    log(`Committed: ${message}`);
  }

  async getBranches(): Promise<GitBranch[]> {
    const summary = await this.git.branch(["-a"]);
    const branches: GitBranch[] = [];

    for (const [name, b] of Object.entries(summary.branches)) {
      branches.push({
        name: b.name,
        is_current: b.current,
        is_remote: name.startsWith("remotes/"),
      });
    }

    return branches;
  }

  async checkout(branch: string): Promise<void> {
    await this.git.checkout(branch);
    log(`Checked out: ${branch}`);
  }

  async pull(): Promise<void> {
    await this.git.pull();
    log("Pulled latest changes");
  }

  async push(): Promise<void> {
    await this.git.push();
    log("Pushed changes");
  }
}
