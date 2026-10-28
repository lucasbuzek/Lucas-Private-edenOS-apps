#!/bin/bash
# AppleRAVEN — owner-private Mac M1 one-click setup candidate.
# Embedded agent; no download, sudo, Mac admin or duplicate installation.
set -euo pipefail

if [[ "${1:-}" == "--dry-run" ]]; then
  echo 'AppleRAVEN: installer syntax/delivery check only; nothing changed.'
  exit 0
fi

if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
  echo 'AppleRAVEN requires an Apple Silicon Mac with macOS. No files changed.' >&2
  exit 1
fi
if [[ "$(id -u)" == 0 ]]; then
  echo 'Run this as your normal Mac account, NOT with sudo.' >&2
  exit 1
fi
PYTHON="$(command -v python3 || true)"
if [[ -z "$PYTHON" ]] || ! "$PYTHON" -c 'import sys; sys.exit(0 if sys.version_info >= (3,9) else 1)' >/dev/null 2>&1; then
  echo 'Python 3.9+ is required. No files changed.' >&2
  exit 1
fi

DEST="$HOME/Library/Application Support/AppleRAVEN"
PLIST="$HOME/Library/LaunchAgents/com.lucasbuzek.appleraven.agent.plist"
LABEL='com.lucasbuzek.appleraven.agent'
EXPECTED='0dbda9bde1b5b68cf4b36f295299c2e2bde577dc8971cdad96b9cdffcab923c0'

# Refuse to overwrite unrecognized or existing original AppleRAVEN agent and launch configuration.
if [[ -e "$DEST/agent.py" ]]; then
  ACTUAL="$(/usr/bin/shasum -a 256 "$DEST/agent.py" | /usr/bin/awk '{print $1}')"
  if [[ "$ACTUAL" != "$EXPECTED" ]]; then
    echo 'Another AppleRAVEN agent already exists. Preserving it; no changes made.' >&2
    exit 1
  fi
  echo 'Recognized AppleRAVEN candidate already installed; preserving original file.'
elif [[ -e "$PLIST" ]]; then
  echo 'An existing AppleRAVEN launch configuration was found; preserving it. No changes made.' >&2
  exit 1
else
  /bin/mkdir -p "$DEST" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
  TMPFILE="$(/usr/bin/mktemp "$DEST/.agent.XXXXXXXX")"
  trap '/bin/rm -f "$TMPFILE"' EXIT
  B64='IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJPd25lci1wcml2YXRlIEFwcGxlUkFWRU4gTWFjIGFnZW50IGNhbmRpZGF0ZS4gT25seSBhbiBhbGxvd2xpc3RlZCBuYXRpdmUgcmVhZC4KCkJhc2VkIG9uIHRoZSBleGlzdGluZyBvd25lci1vd25lZCBSYXZlbiBvdXRib3VuZCBwb2xsL2NsYWltIHBhdHRlcm47IGludGVudGlvbmFsbHkKaW5kZXBlbmRlbnQgb2YgQklGUk9TVCBzb3VyY2UvcnVudGltZS4gTm8gbGlzdGVuaW5nIHBvcnQsIGdlbmVyaWMgc2hlbGwsIG9yCnNjcmVlbi9QaG90b3MvTWVzc2FnZXMvY3JlZGVudGlhbHMgdG9vbC4KClJlcXVpcmVzIHRoZSBkZWRpY2F0ZWQgQXBwbGVSQVZFTiBkZXZpY2UgYmFja2VuZCB0byBzdXBwb3J0IC92MS97cGFpcixzdGFydCwKc3RhdHVzLHN0YXRlLG5leHQscmVzdWx0fS4gVGhlIGN1cnJlbnRseSBkZXBsb3llZCBvd25lci1vbmx5IFdvcmtlciBkb2VzIE5PVC4KIiIiCmZyb20gX19mdXR1cmVfXyBpbXBvcnQgYW5ub3RhdGlvbnMKaW1wb3J0IGFyZ3BhcnNlCmltcG9ydCBoYXNobGliCmltcG9ydCBqc29uCmltcG9ydCBvcwppbXBvcnQgcGxhdGZvcm0KaW1wb3J0IHNlY3JldHMKaW1wb3J0IHNodXRpbAppbXBvcnQgc29ja2V0CmltcG9ydCBzdWJwcm9jZXNzCmltcG9ydCBzeXMKaW1wb3J0IHRpbWUKaW1wb3J0IHVybGxpYi5lcnJvcgppbXBvcnQgdXJsbGliLnJlcXVlc3QKZnJvbSBwYXRobGliIGltcG9ydCBQYXRoCgpTRVJWSUNFID0gJ2NvbS5sdWNhc2J1emVrLmFwcGxlcmF2ZW4uZGV2aWNlJwpFTkRQT0lOVCA9ICdodHRwczovL2FwcGxlcmF2ZW4tZGV2aWNlLmx1Y2FzcmF2ZW5zbmVzdC53b3JrZXJzLmRldicKTUFYX1JFUExZID0gODE5MgoKY2xhc3MgUmVqZWN0ZWQoRXhjZXB0aW9uKToKICAgIHBhc3MKCmNsYXNzIE5vUmVkaXJlY3QodXJsbGliLnJlcXVlc3QuSFRUUFJlZGlyZWN0SGFuZGxlcik6CiAgICBkZWYgcmVkaXJlY3RfcmVxdWVzdChzZWxmLCByZXEsIGZwLCBjb2RlLCBtc2csIGhlYWRlcnMsIG5ld3VybCk6CiAgICAgICAgcmFpc2UgUmVqZWN0ZWQoJ0FwcGxlUkFWRU4gc2VydmljZSByZWRpcmVjdCByZWZ1c2VkJykKCmRlZiBwb3N0KGVuZHBvaW50LCBwYXRoLCBwYXlsb2FkLCB0b2tlbj1Ob25lLCB0aW1lb3V0PTE1KToKICAgIGlmIGVuZHBvaW50ICE9IEVORFBPSU5UOgogICAgICAgIHJhaXNlIFJlamVjdGVkKCdPbmx5IHRoZSBwaW5uZWQgQXBwbGVSQVZFTiBIVFRQUyBzZXJ2aWNlIG9yaWdpbiBpcyBwZXJtaXR0ZWQnKQogICAgYm9keSA9IGpzb24uZHVtcHMocGF5bG9hZCwgc2VwYXJhdG9ycz0oJywnLCAnOicpKS5lbmNvZGUoKQogICAgaWYgbGVuKGJvZHkpID4gMjA0ODoKICAgICAgICByYWlzZSBSZWplY3RlZCgnUmVxdWVzdCBleGNlZWRzIGRldmljZSBzZXJ2aWNlIGxpbWl0JykKICAgIGhlYWRlcnMgPSB7J0NvbnRlbnQtVHlwZSc6ICdhcHBsaWNhdGlvbi9qc29uJywgJ1VzZXItQWdlbnQnOiAnQXBwbGVSQVZFTi1NYWMvMC4xLWNhbmRpZGF0ZSd9CiAgICBpZiB0b2tlbjoKICAgICAgICBoZWFkZXJzWydBdXRob3JpemF0aW9uJ10gPSAnQmVhcmVyICcgKyB0b2tlbgogICAgcmVxID0gdXJsbGliLnJlcXVlc3QuUmVxdWVzdChlbmRwb2ludCArIHBhdGgsIGRhdGE9Ym9keSwgaGVhZGVycz1oZWFkZXJzLCBtZXRob2Q9J1BPU1QnKQogICAgdHJ5OgogICAgICAgIHdpdGggdXJsbGliLnJlcXVlc3QuYnVpbGRfb3BlbmVyKE5vUmVkaXJlY3QoKSkub3BlbihyZXEsIHRpbWVvdXQ9dGltZW91dCkgYXMgcjoKICAgICAgICAgICAgaWYgci5zdGF0dXMgPT0gMjA0OgogICAgICAgICAgICAgICAgcmV0dXJuIHt9CiAgICAgICAgICAgIHJhdyA9IHIucmVhZChNQVhfUkVQTFkrMSkKICAgICAgICAgICAgaWYgbGVuKHJhdykgPiBNQVhfUkVQTFk6CiAgICAgICAgICAgICAgICByYWlzZSBSZWplY3RlZCgnQmFja2VuZCByZXNwb25zZSB0b28gbGFyZ2UnKQogICAgICAgICAgICByZXR1cm4ganNvbi5sb2FkcyhyYXcpCiAgICBleGNlcHQgdXJsbGliLmVycm9yLkhUVFBFcnJvciBhcyBleDoKICAgICAgICByYWlzZSBSZWplY3RlZCgnQXBwbGVSQVZFTiBzZXJ2aWNlIEhUVFAgJyArIHN0cihleC5jb2RlKSkgZnJvbSBOb25lCgpkZWYga2V5Y2hhaW5fZ2V0KCk6CiAgICByID0gc3VicHJvY2Vzcy5ydW4oWycvdXNyL2Jpbi9zZWN1cml0eScsJ2ZpbmQtZ2VuZXJpYy1wYXNzd29yZCcsJy1zJyxTRVJWSUNFLCctdyddLCBjYXB0dXJlX291dHB1dD1UcnVlLCB0ZXh0PVRydWUpCiAgICByZXR1cm4gci5zdGRvdXQuc3RyaXAoKSBpZiByLnJldHVybmNvZGUgPT0gMCBlbHNlIE5vbmUKCmRlZiBrZXljaGFpbl9zZXQodG9rZW4pOgogICAgaWYgbm90IGlzaW5zdGFuY2UodG9rZW4sc3RyKSBvciBsZW4odG9rZW4pICE9IDY0IG9yIGFueShjIG5vdCBpbiAnMDEyMzQ1Njc4OWFiY2RlZicgZm9yIGMgaW4gdG9rZW4pOgogICAgICAgIHJhaXNlIFJlamVjdGVkKCdJbnZhbGlkIGRldmljZSB0b2tlbiBmb3JtYXQ7IHJlZnVzaW5nIHRvIHN0b3JlJykKICAgICMgc2VjdXJpdHkoMSkgcmVjZWl2ZXMgdGhlIGNyZWRlbnRpYWwgaW4gYXJndiAodGhlIG9yaWdpbmFsIFJhdmVuIGJyaWRnZSBhbHNvCiAgICAjIGRvZXMgdGhpcykuIEtlZXAgaXQgb3V0IG9mIGxvZ3MgYW5kIHJldm9rZSBpZiBsb2NhbCBwcm9jZXNzIGV4cG9zdXJlIG1hdHRlcnMuCiAgICBpbXBvcnQgZ2V0cGFzcwogICAgc3VicHJvY2Vzcy5ydW4oWycvdXNyL2Jpbi9zZWN1cml0eScsJ2FkZC1nZW5lcmljLXBhc3N3b3JkJywnLVUnLCctcycsU0VSVklDRSwKICAgICAgJy1hJyxnZXRwYXNzLmdldHVzZXIoKSwnLWwnLCdBcHBsZVJBVkVOIGRldmljZSBjcmVkZW50aWFsJywnLXcnLHRva2VuXSwKICAgICAgc3Rkb3V0PXN1YnByb2Nlc3MuREVWTlVMTCxzdGRlcnI9c3VicHJvY2Vzcy5ERVZOVUxMLGNoZWNrPVRydWUpCgpkZWYgbmF0aXZlX3Nob3J0Y3V0cygpOgogICAgaWYgbm90IHNodXRpbC53aGljaCgnc2hvcnRjdXRzJyk6CiAgICAgICAgcmV0dXJuIHsnb2snOiBGYWxzZSwgJ2Vycm9yJzogJ21hY09TIFNob3J0Y3V0cyBDTEkgdW5hdmFpbGFibGUnfQogICAgdHJ5OgogICAgICAgIHIgPSBzdWJwcm9jZXNzLnJ1bihbJ3Nob3J0Y3V0cycsJ2xpc3QnXSwgY2FwdHVyZV9vdXRwdXQ9VHJ1ZSwgdGV4dD1UcnVlLCB0aW1lb3V0PTIwLCBjaGVjaz1GYWxzZSkKICAgICAgICAjIEJvdW5kIEpTT04tZXNjYXBlZCBieXRlcywgaW5jbHVkaW5nIG5vbi1BU0NJSSBuYW1lcywgYmVsb3cgdGhlCiAgICAgICAgIyBkZXBsb3llZCAyMDQ4LWJ5dGUgcmVxdWVzdCBlbnZlbG9wZS4gUHJlc2VydmUgY29tcGxldGUgY2hhcmFjdGVycy4KICAgICAgICBvdXRwdXQgPSAoci5zdGRvdXQgaWYgci5yZXR1cm5jb2RlPT0wIGVsc2Ugci5zdGRlcnIpLnN0cmlwKClbOjI4MDBdCiAgICAgICAgdHJ1bmNhdGVkID0gRmFsc2UKICAgICAgICB3aGlsZSBsZW4oanNvbi5kdW1wcyhvdXRwdXQpLmVuY29kZSgpKSA+IDE1MDA6CiAgICAgICAgICAgIG91dHB1dCA9IG91dHB1dFs6LTFdCiAgICAgICAgICAgIHRydW5jYXRlZCA9IFRydWUKICAgICAgICByZXR1cm4geydvayc6IHIucmV0dXJuY29kZT09MCwgJ3Nob3J0Y3V0cyc6IG91dHB1dCBpZiByLnJldHVybmNvZGU9PTAgZWxzZSAnJywgJ3RydW5jYXRlZCc6IHRydW5jYXRlZCBvciBsZW4oci5zdGRvdXQuc3RyaXAoKSkgPiAyODAwLCAnZXJyb3InOiAnJyBpZiByLnJldHVybmNvZGU9PTAgZWxzZSAnU2hvcnRjdXRzIGNvbW1hbmQgZmFpbGVkJ30KICAgIGV4Y2VwdCAoc3VicHJvY2Vzcy5UaW1lb3V0RXhwaXJlZCwgT1NFcnJvcik6CiAgICAgICAgcmV0dXJuIHsnb2snOiBGYWxzZSwgJ2Vycm9yJzogJ1Nob3J0Y3V0cyBsaXN0aW5nIHRpbWVkIG91dCBvciBpcyB1bmF2YWlsYWJsZSd9CgpkZWYgcGFpcihlbmRwb2ludCk6CiAgICBpZiBwbGF0Zm9ybS5zeXN0ZW0oKSAhPSAnRGFyd2luJzoKICAgICAgICByYWlzZSBSZWplY3RlZCgnUGFpcmluZyBtdXN0IGJlIHBlcmZvcm1lZCBvbiBtYWNPUycpCiAgICBpZiBrZXljaGFpbl9nZXQoKToKICAgICAgICByYWlzZSBSZWplY3RlZCgnQSBjcmVkZW50aWFsIGFscmVhZHkgZXhpc3RzLiBEbyBub3Qgc2lsZW50bHkgcmVwbGFjZSBpdDsgdXNlIC0tc3RhdHVzLicpCiAgICBjbGllbnRfc2VjcmV0ID0gc2VjcmV0cy50b2tlbl9oZXgoMzIpCiAgICBkYXRhID0gcG9zdChlbmRwb2ludCwnL3YxL3BhaXIvc3RhcnQnLHsnZGV2aWNlX25hbWUnOnNvY2tldC5nZXRob3N0bmFtZSgpWzo2NF0sJ2NoYWxsZW5nZSc6aGFzaGxpYi5zaGEyNTYoY2xpZW50X3NlY3JldC5lbmNvZGUoKSkuaGV4ZGlnZXN0KCl9KQogICAgcmVxdWVzdF9pZCA9IGRhdGEuZ2V0KCdyZXF1ZXN0X2lkJykKICAgIGNvZGUgPSBkYXRhLmdldCgnY29kZScpCiAgICBpZiBub3QgaXNpbnN0YW5jZShyZXF1ZXN0X2lkLHN0cikgb3Igbm90IGlzaW5zdGFuY2UoY29kZSxzdHIpOgogICAgICAgIHJhaXNlIFJlamVjdGVkKCdQYWlyaW5nIG5vdCBhdmFpbGFibGU6IGJhY2tlbmQgZGlkIG5vdCByZXR1cm4gYSB2YWxpZCBjaGFsbGVuZ2UnKQogICAgcHJpbnQoJ09wZW4gdGhpcyBvd25lci1vbmx5IHBhZ2U6IGh0dHBzOi8vYXBwbGVyYXZlbi1wcml2YXRlLmx1Y2FzcmF2ZW5zbmVzdC53b3JrZXJzLmRldi9wYWlyJykKICAgIHByaW50KCdFbnRlciB0aGlzIGNvZGU6ICcrY29kZSkKICAgIHByaW50KCdBdXRoZW50aWNhdGUgd2l0aCB5b3VyIGV4aXN0aW5nIENsb3VkZmxhcmUgQWNjZXNzIG93bmVyIGVtYWlsLiBEbyBub3QgZW50ZXIgYSBwYXNzd29yZCBpbnRvIHRoaXMgc2NyaXB0LicpCiAgICBkZWFkbGluZSA9IHRpbWUubW9ub3RvbmljKCkrNjAwCiAgICB3aGlsZSB0aW1lLm1vbm90b25pYygpPGRlYWRsaW5lOgogICAgICAgIHRpbWUuc2xlZXAoNSkKICAgICAgICB2YWx1ZSA9IHBvc3QoZW5kcG9pbnQsJy92MS9wYWlyL3N0YXR1cycseydyZXF1ZXN0X2lkJzpyZXF1ZXN0X2lkLCdjbGllbnRfc2VjcmV0JzpjbGllbnRfc2VjcmV0fSkKICAgICAgICBpZiB2YWx1ZS5nZXQoJ3N0YXR1cycpID09ICdwZW5kaW5nJzoKICAgICAgICAgICAgY29udGludWUKICAgICAgICBpZiB2YWx1ZS5nZXQoJ3N0YXR1cycpID09ICdhcHByb3ZlZCcgYW5kIHZhbHVlLmdldCgnZGV2aWNlX3Rva2VuJyk6CiAgICAgICAgICAgIGtleWNoYWluX3NldCh2YWx1ZVsnZGV2aWNlX3Rva2VuJ10pCiAgICAgICAgICAgIHByaW50KCdQYWlyaW5nIGFwcHJvdmVkLiBDcmVkZW50aWFsIHNhdmVkIHRvIG1hY09TIEtleWNoYWluLicpCiAgICAgICAgICAgIHJldHVybiBUcnVlCiAgICAgICAgaWYgdmFsdWUuZ2V0KCdzdGF0dXMnKSBpbiAoJ2V4cGlyZWQnLCdyZWplY3RlZCcsJ3Jldm9rZWQnKToKICAgICAgICAgICAgcmFpc2UgUmVqZWN0ZWQoJ1BhaXJpbmcgJyt2YWx1ZVsnc3RhdHVzJ10pCiAgICByYWlzZSBSZWplY3RlZCgnUGFpcmluZyBleHBpcmVkIGFmdGVyIHRlbiBtaW51dGVzOyByZXN0YXJ0IHBhaXJpbmcuJykKCmRlZiBvbmNlKGVuZHBvaW50KToKICAgIHRva2VuID0ga2V5Y2hhaW5fZ2V0KCkKICAgIGlmIG5vdCB0b2tlbjoKICAgICAgICByYWlzZSBSZWplY3RlZCgnTWFjIG5vdCBwYWlyZWQ6IHJ1biAtLXBhaXIgZmlyc3QnKQogICAgaGVsbG8gPSBwb3N0KGVuZHBvaW50LCcvdjEvZGV2aWNlL3N0YXRlJyx7CiAgICAgICAgJ2hvc3RuYW1lJzpzb2NrZXQuZ2V0aG9zdG5hbWUoKVs6NjRdLAogICAgICAgICdvcyc6cGxhdGZvcm0ubWFjX3ZlcigpWzBdLCAnbW9kZWwnOidNYWNCb29rIEFpcicsCiAgICAgICAgJ2NhcGFiaWxpdGllcyc6WydzaG9ydGN1dHMubGlzdCddLCAnYWdlbnQnOicwLjEtY2FuZGlkYXRlJwogICAgICAgIH0sdG9rZW4pCiAgICB0YXNrID0gcG9zdChlbmRwb2ludCwnL3YxL2RldmljZS9uZXh0Jyx7fSx0b2tlbikKICAgIGlmIGlzaW5zdGFuY2UodGFzayxkaWN0KSBhbmQgdGFzay5nZXQoJ2NhcGFiaWxpdHknKSA9PSAnc2hvcnRjdXRzLmxpc3QnIGFuZCBpc2luc3RhbmNlKHRhc2suZ2V0KCdpZCcpLHN0cik6CiAgICAgICAgcmVzdWx0ID0gbmF0aXZlX3Nob3J0Y3V0cygpCiAgICAgICAgcG9zdChlbmRwb2ludCwnL3YxL2RldmljZS9yZXN1bHQnLHsnaWQnOnRhc2tbJ2lkJ10sJ29rJzpyZXN1bHRbJ29rJ10sJ3Jlc3VsdCc6cmVzdWx0fSx0b2tlbikKICAgIGVsaWYgaXNpbnN0YW5jZSh0YXNrLGRpY3QpIGFuZCB0YXNrLmdldCgnY2FwYWJpbGl0eScpOgogICAgICAgIHJhaXNlIFJlamVjdGVkKCdSZWZ1c2luZyBhbiBhY3Rpb24gb3V0c2lkZSB0aGUgYWxsb3dsaXN0JykKICAgIHJldHVybiBoZWxsbwoKZGVmIG1haW4oKToKICAgIGEgPSBhcmdwYXJzZS5Bcmd1bWVudFBhcnNlcihkZXNjcmlwdGlvbj0nQXBwbGVSQVZFTiBkZXZpY2UgY2FuZGlkYXRlIChvd25lci1vbmx5KScpCiAgICBhLmFkZF9hcmd1bWVudCgnLS1wYWlyJyxhY3Rpb249J3N0b3JlX3RydWUnKQogICAgYS5hZGRfYXJndW1lbnQoJy0tb25jZScsYWN0aW9uPSdzdG9yZV90cnVlJykKICAgIGEuYWRkX2FyZ3VtZW50KCctLXN0YXR1cycsYWN0aW9uPSdzdG9yZV90cnVlJykKICAgIGEuYWRkX2FyZ3VtZW50KCctLWVuZHBvaW50JyxkZWZhdWx0PUVORFBPSU5UKQogICAgYXJncz1hLnBhcnNlX2FyZ3MoKQogICAgaWYgYXJncy5zdGF0dXM6CiAgICAgICAgcHJpbnQoanNvbi5kdW1wcyh7J21hY29zJzpwbGF0Zm9ybS5tYWNfdmVyKClbMF0sICdub2RlJzpzb2NrZXQuZ2V0aG9zdG5hbWUoKSwKICAgICAgICAgICdkZXZpY2VfY3JlZGVudGlhbF9wcmVzZW50Jzpib29sKGtleWNoYWluX2dldCgpKSwnZW5kcG9pbnQnOmFyZ3MuZW5kcG9pbnR9LGluZGVudD0yKSkKICAgICAgICByZXR1cm4KICAgIGlmIGFyZ3MucGFpcjoKICAgICAgICBwYWlyKGFyZ3MuZW5kcG9pbnQpCiAgICAgICAgcmV0dXJuCiAgICBpZiBhcmdzLm9uY2U6CiAgICAgICAgb25jZShhcmdzLmVuZHBvaW50KQogICAgICAgIHByaW50KCdSZWFkLW9ubHkgZGV2aWNlIHBvbGwgY29tcGxldGUnKQogICAgICAgIHJldHVybgogICAgd2hpbGUgVHJ1ZToKICAgICAgICB0cnk6CiAgICAgICAgICAgIG9uY2UoYXJncy5lbmRwb2ludCkKICAgICAgICBleGNlcHQgKFJlamVjdGVkLHVybGxpYi5lcnJvci5VUkxFcnJvcixPU0Vycm9yKSBhcyBlOgogICAgICAgICAgICBwcmludCgnQXBwbGVSQVZFTjogJytzdHIoZSksZmlsZT1zeXMuc3RkZXJyKQogICAgICAgIHRpbWUuc2xlZXAoMTUpCgppZiBfX25hbWVfXz09J19fbWFpbl9fJzoKICAgIHRyeToKICAgICAgICBtYWluKCkKICAgIGV4Y2VwdCAoUmVqZWN0ZWQsdXJsbGliLmVycm9yLlVSTEVycm9yLE9TRXJyb3IpIGFzIGU6CiAgICAgICAgcHJpbnQoJ0FwcGxlUkFWRU46ICcrc3RyKGUpLGZpbGU9c3lzLnN0ZGVycikKICAgICAgICBzeXMuZXhpdCgxKQo='
  printf '%s' "$B64" | /usr/bin/base64 -D > "$TMPFILE"
  ACTUAL="$(/usr/bin/shasum -a 256 "$TMPFILE" | /usr/bin/awk '{print $1}')"
  if [[ "$ACTUAL" != "$EXPECTED" ]]; then
    echo 'Agent payload integrity check FAILED. Installation aborted.' >&2
    exit 1
  fi
  /bin/chmod 600 "$TMPFILE"
  /bin/mv "$TMPFILE" "$DEST/agent.py"
  trap - EXIT
  echo 'Installed pinned AppleRAVEN local agent.'
fi

if [[ -e "$PLIST" ]]; then
  # Do not silently overwrite a pre-existing launch configuration; it may be a legitimate LKG.
  echo 'Existing launch-at-login configuration preserved.'
else
  /bin/mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
  "$PYTHON" - "$PYTHON" "$DEST/agent.py" "$PLIST" <<'PYEND'
import pathlib, plistlib, sys
python, agent, path = sys.argv[1:]
p = {'Label':'com.lucasbuzek.appleraven.agent',
     'ProgramArguments':[python, agent],
     'RunAtLoad':True, 'KeepAlive':True,
     'StandardOutPath':str(pathlib.Path.home()/'Library/Logs/AppleRAVEN.log'),
     'StandardErrorPath':str(pathlib.Path.home()/'Library/Logs/AppleRAVEN.error.log')}
pathlib.Path(path).write_bytes(plistlib.dumps(p,sort_keys=True))
PYEND
  /bin/chmod 600 "$PLIST"
  echo 'Created owner-only launch-at-login configuration (not yet running).'
fi

echo 'Unchanged: RDC, existing Raven source, BIFROST, Tailscale, Cloudflare and system permissions.'
echo 'Pairing uses your existing Cloudflare Access owner login; do not paste passwords here.'
if ! "$PYTHON" "$DEST/agent.py" --status; then
  echo 'Local status not available. Configuration retained; pairing not attempted.' >&2
  exit 1
fi

if [[ "$("$PYTHON" - "$DEST/agent.py" <<'PYEND'
import subprocess,sys
p=subprocess.run([sys.executable,sys.argv[1],'--status'],capture_output=True,text=True)
if p.returncode:
 print('unknown')
else:
 import json
 print('yes' if json.loads(p.stdout).get('device_credential_present') else 'no')
PYEND
)" == 'yes' ]]; then
  echo 'An existing device credential was detected; will not re-pair or replace it.'
else
  read -r -p 'Start owner-approved Mac pairing now? [y/N] ' ANSWER
  if [[ "$ANSWER" != [yY] ]]; then
    echo 'Pairing skipped. Local files remain installed; device agent NOT running.'
    exit 0
  fi
  "$PYTHON" "$DEST/agent.py" --pair || {
    echo 'Pairing did not complete; the agent was NOT started.' >&2
    exit 1
  }
fi

# A process is not accepted merely because launchctl bootstrap was attempted.
SERVICE="gui/$(id -u)/$LABEL"
if ! /bin/launchctl print "$SERVICE" >/dev/null 2>&1; then
  if ! /bin/launchctl bootstrap "gui/$(id -u)" "$PLIST"; then
    echo 'launchctl bootstrap failed. Credentials and configuration preserved for repair.' >&2
    exit 1
  fi
fi
if ! /bin/launchctl kickstart -k "$SERVICE"; then
  echo 'Mac service failed to start. Installation exists, but connection is NOT accepted.' >&2
  exit 1
fi
if ! /bin/launchctl print "$SERVICE" >/dev/null 2>&1; then
  echo 'Mac service not present after launch. Connection NOT accepted.' >&2
  exit 1
fi

echo 'AppleRAVEN agent loaded. This does NOT by itself prove cloud pairing or native action acceptance.'
echo 'Check status: open the setup file again (the existing candidate and credentials will be preserved).'
echo 'Agent log: ~/Library/Logs/AppleRAVEN.log'
