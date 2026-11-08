import {randomBytes} from 'node:crypto';
import {open, chmod} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {dirname, resolve} from 'node:path';
const dir=resolve(dirname(fileURLToPath(import.meta.url)), '../postiz');
const content=[
  'POSTIZ_IMAGE=ghcr.io/gitroomhq/postiz-app:v2.25.3',
  'PUBLIC_URL=http://127.0.0.1:4007',
  `JWT_SECRET=${randomBytes(48).toString('hex')}`,
  `POSTGRES_PASSWORD=${randomBytes(32).toString('hex')}`,
  `TEMPORAL_POSTGRES_PASSWORD=${randomBytes(32).toString('hex')}`,
  'BRAGI_DISABLE_REGISTRATION=true',
  ''
].join('\n');
let file;
try {
  file=await open(resolve(dir,'.env'),'wx',0o600);
  await file.writeFile(content);
  await file.close(); file=null;
  await chmod(resolve(dir,'.env'),0o600);
  console.log('Created private postiz/.env (0600); registration disabled; no secrets displayed.');
} catch(error) {
  await file?.close();
  if(error.code==='EEXIST') { console.error('Existing .env preserved; refused overwrite.'); process.exitCode=1; }
  else throw error;
}
