#!/usr/bin/env python3
"""Minimal Swift lexer for balance checking: handles // and nested /* */ comments, "..." and \"\"\"...\"\"\" strings,
raw-ish escapes and nested string interpolation \\( ... ). Reports first imbalance with line numbers. Static aid only (not a compiler)."""
import sys

def check(text, name="<src>"):
    i, n, line = 0, len(text), 1
    stack = []            # (char, line)
    problems = []
    pairs = {')': '(', ']': '[', '}': '{'}
    def skip_string(i, line, multiline):
        # i is just after the opening quote(s); returns (i, line) after closing; handles interpolation recursively
        while i < n:
            c = text[i]
            if c == '\n':
                line += 1
                if not multiline: problems.append((line - 1, "unterminated string literal")); return i + 1, line
            if c == '\\':
                if i + 1 < n and text[i + 1] == '(':
                    i += 2; depth = 1
                    while i < n and depth:
                        d = text[i]
                        if d == '\n': line += 1
                        if d == '"':
                            if text.startswith('"""', i): i, line = skip_string(i + 3, line, True); continue
                            i, line = skip_string(i + 1, line, False); continue
                        if d == '(': depth += 1
                        elif d == ')': depth -= 1
                        i += 1
                    continue
                i += 2; continue
            if multiline and text.startswith('"""', i): return i + 3, line
            if not multiline and c == '"': return i + 1, line
            i += 1
        problems.append((line, "unterminated string at EOF")); return i, line
    while i < n:
        c = text[i]
        if c == '\n': line += 1; i += 1; continue
        if text.startswith('//', i):
            while i < n and text[i] != '\n': i += 1
            continue
        if text.startswith('/*', i):
            depth = 1; i += 2
            while i < n and depth:
                if text.startswith('/*', i): depth += 1; i += 2
                elif text.startswith('*/', i): depth -= 1; i += 2
                else:
                    if text[i] == '\n': line += 1
                    i += 1
            continue
        if c == '"':
            if text.startswith('"""', i): i, line = skip_string(i + 3, line, True)
            else: i, line = skip_string(i + 1, line, False)
            continue
        if c in '([{': stack.append((c, line))
        elif c in ')]}':
            if not stack: problems.append((line, "unmatched " + c))
            else:
                o, ol = stack.pop()
                if o != pairs[c]: problems.append((line, "mismatch: %s opened line %d closed by %s" % (o, ol, c)))
        i += 1
    for o, ol in stack: problems.append((ol, "unclosed " + o))
    return problems

if __name__ == "__main__":
    bad = 0
    for p in sys.argv[1:]:
        with open(p, encoding="utf-8") as fh: pr = check(fh.read(), p)
        print(("OK   " if not pr else "FAIL ") + p)
        for line, msg in pr[:5]: print("    line %d: %s" % (line, msg)); bad += 1
    sys.exit(1 if bad else 0)
