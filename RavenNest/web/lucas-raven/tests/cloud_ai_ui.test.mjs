import test from "node:test";
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
const html=readFileSync(new URL("../public/index.html",import.meta.url),"utf8");
const js=readFileSync(new URL("../public/app.js",import.meta.url),"utf8");
test("Cloud AI has a separate consent form and text field",()=>{
  for(const id of ["cloudAIForm","cloudAIPrompt","cloudAIConsent","cloudAISubmit","cloudAIResult","cloudAIStatus"])
    assert.ok(html.includes('id="'+id+'"'));
  assert.match(html,/id="cloudAIConsent"[^>]*required/);
  assert.match(html,/id="cloudAISubmit"[^>]*disabled/);
});
test("Cloud task only sends to a permitted cloud worker",()=>{
  assert.ok(js.includes('node_id:"lucas-cloud", capability:"ai.infer"'));
  assert.ok(js.includes('consent:"send_to_cloud_provider"'));
  assert.ok(js.includes('node.meta?.actions?.includes("ai.infer")'));
  assert.ok(js.includes('cloudBusy || !cloudAvailable'));
  assert.ok(js.includes('el("p", "message assistant", output)'));
});
