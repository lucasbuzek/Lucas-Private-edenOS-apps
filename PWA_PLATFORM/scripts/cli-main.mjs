import { realpathSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

/** Correctly identify npm bin symlinks as CLI invocations; importing modules remains inert. */
export function isCliMain(metaUrl, entryPath = process.argv[1]) {
  if (!entryPath) return false;
  try {
    return realpathSync(entryPath) === realpathSync(fileURLToPath(metaUrl));
  } catch {
    return false;
  }
}
