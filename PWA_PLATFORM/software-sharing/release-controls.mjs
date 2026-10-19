import {validateEmailLinkReleases} from './email-links.mjs';
import {normalizeEmail} from '../closed-testing/d1.mjs';

/**
 * A reviewed package manifest is immutable. This small D1 overlay only lets
 * Lucas enable/revoke already accepted releases, independently per app.
 * No D1 setting can add an asset or alter its SHA256 and source repository.
 */
export function createD1ReleaseControls({db,releases}={}) {
  if(typeof db?.prepare!=='function'||!validateEmailLinkReleases(releases).ok)
    throw new TypeError('Dedicated D1 and accepted immutable release registry required');
  const accepted=new Map(releases.map(r=>[r.appId+':'+r.releaseId,r]));
  return Object.freeze({
    async isEnabled(appId,releaseId) {
      if(!accepted.has(appId+':'+releaseId))return false;
      const record=await db.prepare(
        'SELECT enabled FROM software_release_controls WHERE app_id=? AND release_id=?'
      ).bind(appId,releaseId).first();
      return record?.enabled===1;
    },
    async list() {
      const items=[];
      for(const entry of releases){
        items.push({appId:entry.appId,releaseId:entry.releaseId,
          filename:entry.filename,enabled:await this.isEnabled(entry.appId,entry.releaseId)});
      }
      return items;
    },
    async setEnabled({appId,releaseId,enabled,reviewer,at}) {
      if(!accepted.has(appId+':'+releaseId)||typeof enabled!=='boolean'||
        !normalizeEmail(reviewer)||!Number.isSafeInteger(at))return false;
      await db.prepare(
        'INSERT INTO software_release_controls (app_id,release_id,enabled,changed_by,changed_at) VALUES (?,?,?,?,?) '+
        'ON CONFLICT(app_id,release_id) DO UPDATE SET enabled=excluded.enabled,'+
        'changed_by=excluded.changed_by,changed_at=excluded.changed_at'
      ).bind(appId,releaseId,enabled?1:0,normalizeEmail(reviewer),at).run();
      return true;
    },
  });
}
