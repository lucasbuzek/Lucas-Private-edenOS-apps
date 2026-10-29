"""Browser WebMCP adapter to the ORIGINAL BIFROST read-only MCP/shortCALL authority.

Do not implement scripts or remote/provider execution here. The existing MCP
bridge resolves every call against its current manifest and host allowances.
"""
import mcp_bridge

MAX_BROWSER_TOOLS = 64


def tools():
    """Only currently available existing read-only shortNameCall actions."""
    result=[]
    for item in mcp_bridge.tools():
        if item.get('annotations', {}).get('readOnlyHint') is not True:
            continue
        if len(result) >= MAX_BROWSER_TOOLS:
            break
        result.append({'name':item['name'], 'description':item['description'],
                       'inputSchema':item['inputSchema'],
                       'annotations':{'readOnlyHint':True,'destructiveHint':False,
                                      'untrustedContentHint':True}})
    return result


def call(name, arguments):
    if (not isinstance(name,str) or type(arguments) is not dict or arguments
            or name not in {tool['name'] for tool in tools()}):
        raise ValueError('Unregistered, unavailable or unsupported WebMCP request')
    response=mcp_bridge.Session().run_tool(1,{'name':name,'arguments':{}},modern=False)
    if 'error' in response:
        raise ValueError('Existing shortNameCall authority denied tool')
    result=response.get('result')
    if not isinstance(result,dict):
        raise ValueError('Unusable tool result')
    return result
