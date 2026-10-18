import { basename, isAbsolute, join, relative, resolve, sep } from 'node:path';
import { cpSync, existsSync, lstatSync, mkdtempSync, realpathSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';

const SKIP = new Set(['.git', '.DS_Store', '.netlify', '.wrangler', 'node_modules', 'dist', 'coverage', '.next', '.nuxt', '.cache', '.npmrc']);
const PRIVATE_ENV = /^(\.env(?:\.|$)|\.dev\.vars(?:\.|$))/;

export function resolveInside(root, child) {
  if (typeof child !== 'string' || !child.trim() || isAbsolute(child) || child.includes('\\') ||
      child.includes('\0') || child.split('/').some(segment => segment === '..' || segment === '')) {
    throw new Error('Path must be a safe relative path');
  }
  const base = resolve(root);
  const target = resolve(base, child);
  if (target !== base && !target.startsWith(base + sep)) throw new Error('Path escapes its configured root');
  return target;
}

export function stageApplication(appRoot, projectDirectory) {
  if (!appRoot) throw new Error('Application source root is required');
  const root = realpathSync(appRoot);
  const source = realpathSync(resolveInside(root, projectDirectory));
  if (source !== root && !source.startsWith(root + sep)) throw new Error('Project symlink escapes application root');
  if (!lstatSync(source).isDirectory()) throw new Error('Application project directory must be a directory');
  const temp = mkdtempSync(join(tmpdir(), 'edenos-pwa-stage-'));
  const staged = join(temp, 'source');
  try {
    cpSync(source, staged, {
      recursive: true,
      force: false,
      errorOnExist: true,
      filter: (entry) => {
        if (lstatSync(entry).isSymbolicLink()) return false;
        if (entry === source) return true;
        const names = relative(source, entry).split(sep);
        return !names.some(name => SKIP.has(name) || PRIVATE_ENV.test(name));
      },
    });
  } catch (error) {
    rmSync(temp, { recursive: true, force: true });
    throw error;
  }
  let disposed = false;
  return {
    source,
    staged,
    dispose() {
      if (disposed) return;
      disposed = true;
      rmSync(temp, { recursive: true, force: true });
    },
  };
}
