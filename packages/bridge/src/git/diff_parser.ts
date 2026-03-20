import type { DiffFile, DiffHunk, DiffLine } from "../types";

const FILE_HEADER_RE = /^diff --git a\/(.*) b\/(.*)$/;
const OLD_FILE_RE = /^--- (?:a\/(.*)|\/(dev\/null))$/;
const NEW_FILE_RE = /^\+\+\+ (?:b\/(.*)|\/(dev\/null))$/;
const HUNK_HEADER_RE = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)$/;

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

    // Skip "index ..." lines
    while (i < lines.length && lines[i].startsWith("index ")) {
      i++;
    }

    // Parse --- line
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

    // Parse +++ line
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

    // Parse hunks
    while (i < lines.length) {
      const hunkLine = lines[i];

      // Stop if we hit the next file header
      if (FILE_HEADER_RE.test(hunkLine)) {
        break;
      }

      const hunkMatch = HUNK_HEADER_RE.exec(hunkLine);
      if (!hunkMatch) {
        i++;
        continue;
      }

      const oldStart = parseInt(hunkMatch[1], 10);
      const oldCount = hunkMatch[2] !== undefined ? parseInt(hunkMatch[2], 10) : 1;
      const newStart = parseInt(hunkMatch[3], 10);
      const newCount = hunkMatch[4] !== undefined ? parseInt(hunkMatch[4], 10) : 1;
      const header = hunkLine;
      i++;

      const diffLines: DiffLine[] = [];
      let oldLineNum = oldStart;
      let newLineNum = newStart;

      while (i < lines.length) {
        const dl = lines[i];

        if (FILE_HEADER_RE.test(dl) || HUNK_HEADER_RE.test(dl)) {
          break;
        }

        if (dl.startsWith("+")) {
          diffLines.push({
            type: "addition",
            content: dl.slice(1),
            new_line_number: newLineNum++,
          });
        } else if (dl.startsWith("-")) {
          diffLines.push({
            type: "deletion",
            content: dl.slice(1),
            old_line_number: oldLineNum++,
          });
        } else if (dl.startsWith(" ") || dl === "") {
          diffLines.push({
            type: "context",
            content: dl.startsWith(" ") ? dl.slice(1) : dl,
            old_line_number: oldLineNum++,
            new_line_number: newLineNum++,
          });
        } else if (dl.startsWith("\\")) {
          // "\ No newline at end of file" — skip
        }

        i++;
      }

      hunks.push({
        old_start: oldStart,
        old_count: oldCount,
        new_start: newStart,
        new_count: newCount,
        header,
        lines: diffLines,
      });
    }

    files.push({
      old_path: oldPath,
      new_path: newPath,
      is_new: isNew,
      is_deleted: isDeleted,
      is_renamed: isRenamed,
      hunks,
    });
  }

  return files;
}
