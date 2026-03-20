import type { DiffFile, DiffHunk, DiffLine } from "../types";

const FILE_HEADER_RE = /^diff --git a\/(.*) b\/(.*)$/;
const OLD_FILE_RE = /^--- (?:a\/(.*)|\/(dev\/null))$/;
const NEW_FILE_RE = /^\+\+\+ (?:b\/(.*)|\/(dev\/null))$/;
const HUNK_HEADER_RE = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)$/;

function determineFileStatus(
  isNew: boolean,
  isDeleted: boolean,
  isRenamed: boolean,
): DiffFile["status"] {
  if (isNew) {
    return "added";
  }
  if (isDeleted) {
    return "deleted";
  }
  if (isRenamed) {
    return "renamed";
  }
  return "modified";
}

export function parseDiff(rawDiff: string): DiffFile[] {
  const files: DiffFile[] = [];
  if (!rawDiff || rawDiff.trim().length === 0) {
    return files;
  }

  const lines = rawDiff.split("\n");
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];

    const fileHeaderMatch = FILE_HEADER_RE.exec(line);
    if (!fileHeaderMatch) {
      i++;
      continue;
    }

    const oldPathRaw = fileHeaderMatch[1];
    const newPathRaw = fileHeaderMatch[2];
    i++;

    let oldPath = oldPathRaw;
    let newPath = newPathRaw;
    let isNew = false;
    let isDeleted = false;
    let isRenamed = oldPath !== newPath;

    while (i < lines.length && lines[i].startsWith("index ")) {
      i++;
    }

    if (i < lines.length) {
      const oldMatch = OLD_FILE_RE.exec(lines[i]);
      if (oldMatch) {
        if (lines[i] === "--- /dev/null") {
          isNew = true;
        } else if (oldMatch[1]) {
          oldPath = oldMatch[1];
        }
        i++;
      }
    }

    if (i < lines.length) {
      const newMatch = NEW_FILE_RE.exec(lines[i]);
      if (newMatch) {
        if (lines[i] === "+++ /dev/null") {
          isDeleted = true;
        } else if (newMatch[1]) {
          newPath = newMatch[1];
        }
        i++;
      }
    }

    const hunks: DiffHunk[] = [];
    let additions = 0;
    let deletions = 0;

    while (i < lines.length) {
      const hunkLine = lines[i];

      if (FILE_HEADER_RE.test(hunkLine)) {
        break;
      }

      const hunkMatch = HUNK_HEADER_RE.exec(hunkLine);
      if (!hunkMatch) {
        i++;
        continue;
      }

      const oldStart = parseInt(hunkMatch[1], 10);
      const oldLines = hunkMatch[2] !== undefined ? parseInt(hunkMatch[2], 10) : 1;
      const newStart = parseInt(hunkMatch[3], 10);
      const newLines = hunkMatch[4] !== undefined ? parseInt(hunkMatch[4], 10) : 1;
      const header = hunkLine;
      i++;

      const diffLines: DiffLine[] = [];
      let oldLineNum = oldStart;
      let newLineNum = newStart;

      while (i < lines.length) {
        const diffLine = lines[i];

        if (FILE_HEADER_RE.test(diffLine) || HUNK_HEADER_RE.test(diffLine)) {
          break;
        }

        if (diffLine.startsWith("+")) {
          additions++;
          diffLines.push({
            type: "added",
            content: diffLine.slice(1),
            new_line_number: newLineNum++,
          });
        } else if (diffLine.startsWith("-")) {
          deletions++;
          diffLines.push({
            type: "removed",
            content: diffLine.slice(1),
            old_line_number: oldLineNum++,
          });
        } else if (diffLine.startsWith(" ") || diffLine === "") {
          diffLines.push({
            type: "context",
            content: diffLine.startsWith(" ") ? diffLine.slice(1) : diffLine,
            old_line_number: oldLineNum++,
            new_line_number: newLineNum++,
          });
        }

        i++;
      }

      hunks.push({
        old_start: oldStart,
        old_lines: oldLines,
        new_start: newStart,
        new_lines: newLines,
        header,
        lines: diffLines,
      });
    }

    files.push({
      path: isDeleted ? oldPath : newPath,
      old_path: oldPath,
      new_path: newPath,
      status: determineFileStatus(isNew, isDeleted, isRenamed),
      additions,
      deletions,
      hunks,
    });
  }

  return files;
}
