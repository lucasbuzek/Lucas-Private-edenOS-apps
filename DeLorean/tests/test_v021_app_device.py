"""Actual SQLite online backup / device capability / manifest anti-drift regression."""
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'core'))
from standalone_backup import DeLorean, Denied, history
from mcp_server import Server, TOOLS

class AppAndDeviceTests(unittest.TestCase):
    def setUp(self):
        t=tempfile.TemporaryDirectory();self.addCleanup(t.cleanup)
        self.root=Path(t.name)
        self.input=self.root/'input';self.input.mkdir()
        self.output=self.root/'output';self.output.mkdir()
        self.db=self.input/'running.sqlite'
        con=sqlite3.connect(self.db);con.execute('PRAGMA journal_mode=WAL')
        con.execute('CREATE TABLE records (id INTEGER PRIMARY KEY, payload TEXT)')
        con.execute('INSERT INTO records(payload) VALUES (?)',('committed v1',));con.commit();con.close()
        self.app=DeLorean(self.root/'delorean',[str(self.input)],[str(self.output)],owner='LucasPRIVATE')
        self.mcp=Server(self.app)
    def test_sqlite_online_transactional_snapshot(self):
        connection=sqlite3.connect(self.db)
        connection.execute('INSERT INTO records(payload) VALUES (?)',('committed WAL',));connection.commit()
        connection.execute('BEGIN')
        connection.execute('INSERT INTO records(payload) VALUES (?)',('uncommitted',))
        snapshot=self.app.sqlite_backup_create(str(self.db),'TestApp','BACKUP SQLITE DATABASE')
        self.assertEqual(snapshot['status'],'SQLITE_ONLINE_BACKUP_HASH_VERIFIED')
        self.assertTrue(self.app.verify_snapshot(snapshot['snapshot_id'])['ok'])
        dest=self.output/'stage'
        self.app.recovery_stage(snapshot['snapshot_id'],str(dest),'RESTORE TO NEW DIRECTORY')
        with sqlite3.connect(dest/self.db.name) as db:
            values=[x[0] for x in db.execute('SELECT payload FROM records ORDER BY id')]
        self.assertEqual(values,['committed v1','committed WAL'])
        connection.rollback();connection.close()
        with sqlite3.connect(self.db) as db:
            self.assertEqual(db.execute('SELECT count(*) FROM records').fetchone()[0],2)
    def test_sqlite_backup_dedup_verified(self):
        a=self.app.sqlite_backup_create(str(self.db),'TestApp','BACKUP SQLITE DATABASE')
        b=self.app.sqlite_backup_create(str(self.db),'TestApp','BACKUP SQLITE DATABASE')
        self.assertEqual(b['status'],'UNCHANGED_SQLITE_REUSED_VERIFIED')
        self.assertEqual(a['snapshot_id'],b['snapshot_id'])
    def test_sqlite_modified_creates_new_snapshot(self):
        a=self.app.sqlite_backup_create(str(self.db),'TestApp','BACKUP SQLITE DATABASE')
        with sqlite3.connect(self.db) as db:db.execute('INSERT INTO records(payload) VALUES (?)',('new value',))
        b=self.app.sqlite_backup_create(str(self.db),'TestApp','BACKUP SQLITE DATABASE')
        self.assertNotEqual(a['snapshot_id'],b['snapshot_id'])
        self.assertEqual(self.app.compare(a['snapshot_id'],b['snapshot_id'])['modified'],[self.db.name])
    def test_sqlite_bad_header_fails_closed(self):
        path=self.input/'not.sqlite';path.write_bytes(b'not an sqlite database')
        with self.assertRaises(Denied):self.app.sqlite_backup_plan(str(path),'A')
    def test_sqlite_denied_external(self):
        path=self.root/'outside.sqlite';path.write_bytes(self.db.read_bytes())
        with self.assertRaises(Denied):self.app.sqlite_backup_create(str(path),'A','BACKUP SQLITE DATABASE')
    def test_sqlite_denied_without_confirmation(self):
        with self.assertRaises(Denied):self.app.sqlite_backup_create(str(self.db),'A','no')
    def test_sqlite_no_clobber_existing_restore(self):
        a=self.app.sqlite_backup_create(str(self.db),'TestApp','BACKUP SQLITE DATABASE')
        target=self.output/'already';target.mkdir()
        with self.assertRaises(history.RecoveryError):
            self.app.recovery_stage(a['snapshot_id'],str(target),'RESTORE TO NEW DIRECTORY')
    def test_sqlite_manifest_tamper_detected(self):
        a=self.app.sqlite_backup_create(str(self.db),'TestApp','BACKUP SQLITE DATABASE')
        file=self.app.catalog/(a['snapshot_id']+'.json')
        d=json.loads(file.read_text());d['files'][0]['size']=0
        file.write_text(json.dumps(d))
        with self.assertRaises(history.RecoveryError):self.app.verify_snapshot(a['snapshot_id'])
    def test_sqlite_no_uncommitted_data(self):
        # A real SQLite online backup must never include an open transaction.
        with sqlite3.connect(self.db) as db:
            db.execute('BEGIN')
            db.execute('INSERT INTO records(payload) VALUES (?)',('pending',))
            result=self.app.sqlite_backup_create(str(self.db),'TestApp','BACKUP SQLITE DATABASE')
            db.rollback()
        target=self.output/'restore-new'
        self.app.recovery_stage(result['snapshot_id'],str(target),'RESTORE TO NEW DIRECTORY')
        with sqlite3.connect(target/self.db.name) as db:
            self.assertEqual(db.execute('SELECT count(*) FROM records').fetchone()[0],1)
    def test_mcp_sqlite_and_device_discovery(self):
        names={x['name'] for x in TOOLS}
        self.assertIn('delorean_sqlite_backup_create',names)
        self.assertIn('delorean_device_recovery_plan',names)
        r=self.mcp.handle({'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':'delorean_device_recovery_plan','arguments':{'device':'iphone'}}})
        self.assertFalse(r['result']['isError'])
        self.assertEqual(r['result']['structuredContent']['result']['full_device_recovery_by_delorean'],'NOT_IMPLEMENTED')
    def test_mcp_sqlite_confirmation_rejected(self):
        r=self.mcp.handle({'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':'delorean_sqlite_backup_create','arguments':{'source':str(self.db),'project':'TestApp','confirmation':'yes'}}})
        self.assertTrue(r['result']['isError'])
    def test_device_recovery_matrix(self):
        for d in ['mac','iphone','ipad','windows','linux','android']:
            plan=self.app.device_recovery_plan(d)
            self.assertEqual(plan['device'],d)
            self.assertFalse(plan['native_full_recovery_tested'])
            self.assertTrue(plan['requires_owner_approval_for_restore'])
    def test_device_unknown_rejected(self):
        with self.assertRaises(Denied):self.app.device_recovery_plan('unknown')
    def test_manifest_renamed_owner_tamper(self):
        a=self.app.sqlite_backup_create(str(self.db),'TestApp','BACKUP SQLITE DATABASE')
        path=self.app.catalog/(a['snapshot_id']+'.json')
        m=json.loads(path.read_text());m['owner']='OtherCouncil';path.write_text(json.dumps(m))
        with self.assertRaises(history.RecoveryError):history.load_manifest(path)

if __name__=='__main__':unittest.main()
