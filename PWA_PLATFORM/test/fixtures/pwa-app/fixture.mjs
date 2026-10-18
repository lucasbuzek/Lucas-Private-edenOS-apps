import { mkdirSync, writeFileSync } from 'node:fs';

const mode = process.argv[2];
if (process.env.EDEN_PWA_TEST_PRIVATE_KEY) throw new Error('Secret build environment leaked into staged scripts');
if (mode === 'install' || mode === 'test') {
  console.log('fixture ' + mode + ' passed');
} else if (mode === 'build') {
  if (process.env.VITE_EDEN_PWA_AUTH_REQUIRED !== 'true') throw new Error('hosted authentication flag was not injected');
  writeFileSync('build-marker.txt', 'ran in staged copy');
  mkdirSync('dist', { recursive: true });
  writeFileSync('dist/index.html', '<!doctype html><title>Fixture PWA</title>');
  writeFileSync('dist/manifest.webmanifest', JSON.stringify({ name: 'Fixture PWA', start_url: '/' }));
} else if (mode === 'auth') {
  if (process.env.VITE_EDEN_PWA_AUTH_REQUIRED !== 'true') throw new Error('auth flag missing in smoke test');
  if (process.env.EXPECTED_HOSTED_AUTH_SCREEN !== 'login') throw new Error('hosted login smoke test was not required');
  console.log('fixture hosted auth smoke passed');
} else {
  throw new Error('unknown fixture mode');
}
