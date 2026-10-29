#!/usr/bin/env python3
"""Offline read-only Safari .webarchive research extractor for BIFROST.

This is a *candidate research helper*, not a production BIFROST MCP tool.
It never opens a browser, runs embedded scripts, contacts a network, or alters inputs.
Optional plain-text output must be explicitly requested in a private directory.
"""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import plistlib
import re
from urllib.parse import urlsplit

MAX_FILE = 64 * 1024 * 1024
MAX_MAIN = 16 * 1024 * 1024
MAX_TEXT = 2 * 1024 * 1024


class TextOnly(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.skip = 0
        self.parts = []
        self.github_repos = set()

    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            href = dict(attrs).get('href', '')
            try:
                u = urlsplit(href)
                segments = u.path.strip('/').split('/')
                if u.scheme == 'https' and u.hostname == 'github.com' and len(segments) >= 2:
                    owner, repo = segments[:2]
                    if owner and repo and owner not in ('.', '..') and repo not in ('.', '..'):
                        self.github_repos.add('https://github.com/' + owner + '/' + repo.removesuffix('.git'))
            except ValueError:
                pass
        if tag in ('style', 'script', 'noscript', 'svg'):
            self.skip += 1
        elif tag in ('p', 'div', 'li', 'section', 'article', 'h1', 'h2', 'h3', 'tr'):
            self.parts.append('\n')

    def handle_endtag(self, tag):
        if tag in ('style', 'script', 'noscript', 'svg') and self.skip:
            self.skip -= 1

    def handle_data(self, data):
        if not self.skip:
            self.parts.append(data)

    def result(self):
        return '\n'.join(filter(None, (re.sub(r'[ \t]+', ' ', p).strip() for p in ''.join(self.parts).splitlines())))[:MAX_TEXT]


def extract(path):
    if path.is_symlink() or not path.is_file():
        raise ValueError('not a regular, non-symlink file')
    size = path.stat().st_size
    if not size or size > MAX_FILE:
        raise ValueError('size outside permitted range')
    payload = path.read_bytes()
    archive = plistlib.loads(payload)
    if not isinstance(archive, dict) or not isinstance(archive.get('WebMainResource'), dict):
        raise ValueError('not a Safari WebArchive main resource')
    main = archive['WebMainResource']
    data = main.get('WebResourceData')
    if not isinstance(data, bytes) or len(data) > MAX_MAIN:
        raise ValueError('missing or oversized main resource')
    mimetype = str(main.get('WebResourceMIMEType', '')).lower()
    if mimetype not in ('text/html', 'application/xhtml+xml', 'text/plain'):
        raise ValueError('unsupported main resource type')
    encoding = main.get('WebResourceTextEncodingName') or 'utf-8'
    if not isinstance(encoding, str) or len(encoding) > 40:
        encoding = 'utf-8'
    try:
        decoded = data.decode(encoding, errors='replace')
    except LookupError:
        decoded = data.decode('utf-8', errors='replace')
    if mimetype == 'text/plain':
        text = decoded[:MAX_TEXT]
    else:
        parser = TextOnly()
        parser.feed(decoded)
        text = parser.result()
    github_repositories = sorted(parser.github_repos)[:25] if mimetype != 'text/plain' else []
    return {'github_repositories': github_repositories, 'sha256': hashlib.sha256(payload).hexdigest(),
            'source_url': str(main.get('WebResourceURL', '')),
            'mime': mimetype, 'bytes': size, 'text_chars': len(text)}, text


def scan(folder, out=None, *, recursive=False):
    folder = Path(folder).expanduser().resolve(strict=True)
    if not folder.is_dir():
        raise ValueError('source must be a directory')
    export = None
    if out is not None:
        export = Path(out).expanduser().resolve()
        if export == folder or folder in export.parents or export in folder.parents:
            raise ValueError('output and source trees must be separate')
        export.mkdir(parents=True, exist_ok=True)
    # Original single-directory mode stays the default. Recursive mode covers
    # archived topic folders without following directory symlinks (Path.rglob
    # does not traverse them by default on Python 3.11+).
    paths = folder.rglob('*') if recursive else folder.iterdir()
    archives = (p for p in paths if p.suffix.lower() == '.webarchive')
    for i, p in enumerate(sorted(archives, key=lambda x: x.relative_to(folder).as_posix().casefold())):
        if i >= 20000:
            raise ValueError('archive count exceeds bounded research limit')
        rec = {'filename': p.name, 'relative_path': p.relative_to(folder).as_posix(),
               'archive_state': 'not_executed'}
        try:
            info, text = extract(p)
            rec.update(info)
            rec['archive_state'] = 'extracted_offline'
            if export is not None:
                target = export / (info['sha256'][:20] + '.txt')
                try:
                    with target.open('x', encoding='utf-8') as handle:
                        handle.write(text)
                except FileExistsError:
                    if target.read_text(encoding='utf-8') != text:
                        raise ValueError('hash-prefix conflict or output modified')
                rec['local_export'] = target.name
        except (ValueError, OSError, TypeError, OverflowError, RecursionError, plistlib.InvalidFileException) as exc:
            rec['archive_state'] = 'unreadable'
            rec['error'] = type(exc).__name__ + ': ' + str(exc)[:140]
        yield rec


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source', required=True, help='Existing directory containing .webarchive files')
    ap.add_argument('--output', help='Explicit separate private directory for plain-text copies')
    ap.add_argument('--recursive', action='store_true', help='Include nested source subfolders without following symlinks')
    args = ap.parse_args()
    for record in scan(args.source, args.output, recursive=args.recursive):
        print(json.dumps(record, ensure_ascii=False, sort_keys=True))


if __name__ == '__main__':
    main()
