import json,sys
for raw in sys.stdin:
 try: p=json.loads(raw)
 except ValueError: continue
 if 'id' not in p:continue
 m=p.get('method')
 if m=='initialize':v={'protocolVersion':'2025-06-18','serverInfo':{'name':'test-donor','version':'1'},'capabilities':{'tools':{}}}
 elif m=='tools/list':v={'tools':[{'name':'search_photos','description':'Read photos'},{'name':'delete_photos','description':'Delete photos'},{'name':'run_shortcut','description':'Run Shortcut'}]}
 elif m=='tools/call':v={'content':[{'type':'text','text':str(p['params']['arguments'])}]}
 else:v={}
 print(json.dumps({'jsonrpc':'2.0','id':p['id'],'result':v}),flush=True)
