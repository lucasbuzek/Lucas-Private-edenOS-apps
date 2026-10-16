import test from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';

test('provider migration preserves existing CRESUS data and is repeat-safe',()=>{
 const db=new DatabaseSync(':memory:');
 const schema=readFileSync(new URL('../schema.sql',import.meta.url),'utf8');
 const migration=readFileSync(new URL('../migrations/0003_intelligence_preferences.sql',import.meta.url),'utf8');
 db.exec(schema);
 // Model an existing deployment that predates the new table.
 db.exec('DROP TABLE intelligence_preferences');
 db.prepare('INSERT INTO users(email,role,status) VALUES (?,?,?)').run('existing@example.com','member','active');
 db.prepare('INSERT INTO conversations(id,email,title) VALUES (?,?,?)').run('existing-conversation','existing@example.com','Retain this');
 db.prepare('INSERT INTO messages(conversation_id,role,content) VALUES (?,?,?)').run('existing-conversation','user','Preserved text');
 db.exec(migration);
 db.prepare('INSERT INTO intelligence_preferences(email,provider) VALUES (?,?)').run('existing@example.com','workers-ai');
 db.exec(migration);
 assert.equal(db.prepare('SELECT title FROM conversations WHERE id=?').get('existing-conversation').title,'Retain this');
 assert.equal(db.prepare('SELECT content FROM messages WHERE conversation_id=?').get('existing-conversation').content,'Preserved text');
 assert.equal(db.prepare('SELECT provider FROM intelligence_preferences WHERE email=?').get('existing@example.com').provider,'workers-ai');
 db.close();
});
