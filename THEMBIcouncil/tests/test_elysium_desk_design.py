#!/usr/bin/env python3
"""Source-only ELYSIUM THEMBIcouncil UI regressions.

Protect existing owner authentication and real task/note/document workflows.
This test does NOT claim a live signed-in user or provider acceptance.
"""
from html.parser import HTMLParser
from pathlib import Path

root = Path(__file__).resolve().parents[1]
site = root / "site"
desk = site / "app" / "desk"

class InspectHTML(HTMLParser):
    def __init__(self):
        super().__init__()
        self.elements = []
        self.ids = []
        self.scripts = []
        self.css = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.elements.append((tag, attrs))
        if attrs.get("id"):
            self.ids.append(attrs["id"])
        if tag == "script" and attrs.get("src"):
            self.scripts.append(attrs["src"])
        if tag == "link" and attrs.get("rel") == "stylesheet":
            self.css.append(attrs.get("href"))

markup = (desk / "index.html").read_text()
parser = InspectHTML()
parser.feed(markup)
assert len(parser.ids) == len(set(parser.ids)), "Duplicate page IDs"
must_exist = {
    "auth-state", "workspace", "welcome-name", "metric-open", "metric-done",
    "metric-notes", "metric-files", "task-progress", "task-list",
    "recent-list", "quick-task", "quick-note", "new-task", "new-note",
    "create-task", "create-note", "logout", "desk-sidebar", "sidebar-toggle",
    "sidebar-backdrop", "desk-search", "desk-command", "command-filter",
    "command-close", "command-results"
}
assert must_exist.issubset(set(parser.ids)), f"Missing core workflow IDs: {must_exist - set(parser.ids)}"
assert any(tag == "div" and a.get("id") == "workspace" and "hidden" in a
           for tag, a in parser.elements), "Workspace must be hidden until authentication"
assert "/app/desk/desk.js" in parser.scripts, "Existing API-backed Desk script lost"
assert "/app/desk/desk-modern.js" in parser.scripts, "Interaction layer missing"
assert "/app/desk/desk.css" in parser.css, "Existing Desk CSS missing"
assert "/app/desk/desk-modern.css" in parser.css, "New styles missing"
assert 'https://thembicouncil-artwork.lucasbuzek.workers.dev/img/terry' in markup
assert 'aria-expanded="false"' in markup and 'aria-controls="desk-sidebar"' in markup
assert 'aria-labelledby="command-title"' in markup
assert not any(tag == "script" and not a.get("src") for tag, a in parser.elements), "Inline scripts violate CSP"

css = (desk / "desk-modern.css").read_text()
assert "@media(max-width:900px)" in css
assert "@media(max-width:700px)" in css
assert "prefers-color-scheme:dark" in css
assert "prefers-reduced-motion:reduce" in css
assert ".visually-hidden" in css and ".sidebar-backdrop" in css

original_js = (desk / "desk.js").read_text()
assert "request('me')" in original_js, "Existing login check changed"
assert "request('items','POST'" in original_js, "Task/note persistence changed"
assert "request('items','PATCH'" in original_js, "Completion persistence changed"
assert "credentials:'same-origin'" in original_js
assert "workspace').hidden=false" in original_js
enhancement = (desk / "desk-modern.js").read_text()
assert "const authenticated = () => !workspace.hidden;" in enhancement
assert "dialog.showModal" in enhancement and "e.metaKey || e.ctrlKey" in enhancement
assert "x.url.startsWith('/')" in enhancement and "!x.url.startsWith('//')" in enhancement
assert "document.body.classList.toggle('nav-open', next)" in enhancement
assert "fetch(" not in enhancement, "Presentation helper must not own API or provider access"

auth = (root / "functions" / "_lib" / "auth.js").read_text()
assert 'Path=/app;' in auth, "ELYSIUM must not broaden session cookie scope"
assert "COUNCIL_PRODUCT_AUTH" in auth and "authenticated(context)" in auth
headers = (site / "_headers").read_text()
assert "frame-ancestors 'none'" in headers and "noindex" in headers

entry = (site / "elysium" / "index.html").read_text()
assert 'content="0;url=/app/desk/"' in entry
assert '/app/desk/' in entry
assert 'id="workspace"' not in entry, "Do not render private workspace at a public entry path"
redirects = (site / "_redirects").read_text()
assert '/elysium /app/desk/ 302' in redirects
assert '/elysium/ /app/desk/ 302' in redirects

print(f"ELYSIUM_DESK_SOURCE_CONTRACT_PASS: {len(parser.ids)} unique IDs; existing API and /app auth preserved; mobile/dark/accessibility/entry verified")
