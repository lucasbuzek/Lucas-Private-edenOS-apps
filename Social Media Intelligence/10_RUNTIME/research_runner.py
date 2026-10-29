#!/usr/bin/env python3
"""Public-source discovery and article capture for Social Media Intelligence.

Discovery outputs are leads, not verified facts. This module never posts or schedules remotely.
Python standard library only.
"""
from __future__ import annotations
import argparse, datetime as dt, email.utils, hashlib, html, ipaddress, json, os, re, socket, sys, time, ssl
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import quote, urlparse, urlunparse, parse_qsl, urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError
import xml.etree.ElementTree as ET

VERSION = "0.1.0"
UA = "SocialMediaIntelligenceResearch/0.1 (+public-source research; contact project owner)"
UTC = dt.timezone.utc

def now_utc():
    return dt.datetime.now(UTC).replace(microsecond=0)

def iso(dtval):
    return dtval.astimezone(UTC).isoformat().replace("+00:00", "Z")

def parse_date(value):
    if not value:
        return None
    value = str(value).strip()
    try:
        parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=UTC)
        return iso(parsed)
    except Exception:
        pass
    try:
        parsed = email.utils.parsedate_to_datetime(value)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=UTC)
        return iso(parsed)
    except Exception:
        return None

def safe_public_url(url):
    try:
        p = urlparse(url)
        if p.scheme not in ("http", "https") or not p.hostname or p.username or p.password:
            return False
        host = p.hostname.lower()
        if host in ("localhost", "localhost.localdomain") or host.endswith(".local"):
            return False
        try:
            ip = ipaddress.ip_address(host)
            if not ip.is_global:
                return False
        except ValueError:
            # Reject obvious local-only hostnames; public DNS is resolved by urllib.
            if "." not in host:
                return False
        return True
    except Exception:
        return False

def canonical_url(url):
    p = urlparse(url)
    q = [(k, v) for k, v in parse_qsl(p.query, keep_blank_values=True)
         if not k.lower().startswith("utm_") and k.lower() not in {"fbclid", "gclid", "mc_cid", "mc_eid"}]
    return urlunparse((p.scheme.lower(), p.netloc.lower(), p.path.rstrip("/") or "/", "", urlencode(q), ""))

class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.title_parts, self.text_parts, self.meta = [], [], {}
        self._in_title = False
        self._skip = 0
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag.lower() == "title": self._in_title = True
        if tag.lower() in ("script", "style", "noscript", "svg", "nav", "footer", "header", "form"): self._skip += 1
        if tag.lower() == "meta":
            key = (a.get("property") or a.get("name") or "").lower()
            val = a.get("content", "").strip()
            if key and val: self.meta[key] = val
        if tag.lower() in ("p", "h1", "h2", "h3", "article", "br", "li"): self.text_parts.append("\n")
    def handle_endtag(self, tag):
        if tag.lower() == "title": self._in_title = False
        if tag.lower() in ("script", "style", "noscript", "svg", "nav", "footer", "header", "form") and self._skip:
            self._skip -= 1
        if tag.lower() in ("p", "h1", "h2", "h3", "li"): self.text_parts.append("\n")
    def handle_data(self, data):
        if self._in_title: self.title_parts.append(data)
        if not self._skip and data.strip(): self.text_parts.append(data.strip() + " ")

def fetch_bytes(url, timeout=8, limit=1_500_000):
    if not safe_public_url(url):
        raise ValueError("URL rejected by public-URL safety check")
    req = Request(url, headers={"User-Agent": UA, "Accept": "text/html,application/rss+xml,application/xml,application/json;q=0.9,*/*;q=0.5"})
    # The python.org macOS build may not use the macOS trust store by default.
    # Prefer the system-maintained CA bundle when present; never disable TLS checks.
    ca_bundle = os.environ.get("SSL_CERT_FILE")
    if not ca_bundle and os.path.isfile("/etc/ssl/cert.pem"):
        ca_bundle = "/etc/ssl/cert.pem"
    tls_context = ssl.create_default_context(cafile=ca_bundle) if ca_bundle else ssl.create_default_context()
    with urlopen(req, timeout=timeout, context=tls_context) as resp:
        final_url = resp.geturl()
        if not safe_public_url(final_url):
            raise ValueError("Redirect target rejected by public-URL safety check")
        ctype = resp.headers.get("Content-Type", "")
        if any(x in ctype.lower() for x in ("image/", "video/", "audio/")):
            raise ValueError("Non-text media URL")
        data = resp.read(limit + 1)
        if len(data) > limit:
            data = data[:limit]
        charset = resp.headers.get_content_charset() or "utf-8"
        return data.decode(charset, errors="replace"), ctype, final_url, resp.status

def get_persona(path):
    if not path:
        return {}
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if data.get("status") == "TEMPLATE_NOT_CONFIGURED":
        raise ValueError("Persona is still a template. Configure a real persona before automatic discovery.")
    return data

def make_candidate(title, url, source, published=None, snippet="", metadata=None):
    url = html.unescape((url or "").strip())
    if not title or not safe_public_url(url):
        return None
    return {
        "candidate_id": hashlib.sha256(canonical_url(url).encode()).hexdigest()[:16],
        "title": re.sub(r"\s+", " ", html.unescape(title)).strip(),
        "url": canonical_url(url),
        "discovery_source": source,
        "published_at": parse_date(published),
        "snippet": re.sub(r"\s+", " ", html.unescape(snippet or "")).strip()[:1200],
        "source_metadata": metadata or {},
        "capture_status": "LEAD_ONLY",
        "claim_verification_status": "NOT_VERIFIED",
    }

def gdelt_search(query, hours, limit):
    start = (now_utc() - dt.timedelta(hours=hours)).strftime("%Y%m%d%H%M%S")
    end = now_utc().strftime("%Y%m%d%H%M%S")
    url = "https://api.gdeltproject.org/api/v2/doc/doc?" + urlencode({
        "query": query, "mode": "ArtList", "format": "json",
        "maxrecords": min(max(int(limit), 1), 250), "sort": "DateDesc",
        "startdatetime": start, "enddatetime": end
    })
    text, _, _, _ = fetch_bytes(url, timeout=8, limit=2_500_000)
    data = json.loads(text)
    out = []
    for a in data.get("articles", []):
        item = make_candidate(a.get("title"), a.get("url"), "GDELT_DOC",
            a.get("seendate"), a.get("socialimage", ""), {
                "domain": a.get("domain"), "language": a.get("language"),
                "source_country": a.get("sourcecountry"), "seen_date": a.get("seendate")
            })
        if item: out.append(item)
    return out

def google_news_search(query, hours, limit):
    # Google News RSS is used as a discovery feed only; not a substitute for publisher pages.
    url = "https://news.google.com/rss/search?" + urlencode({
        "q": query + " when:" + str(max(1, int(hours // 24))) + "d",
        "hl": "en-US", "gl": "US", "ceid": "US:en"
    })
    text, _, _, _ = fetch_bytes(url, timeout=8, limit=2_000_000)
    root = ET.fromstring(text)
    out = []
    for item in root.findall(".//item")[:limit]:
        title = item.findtext("title", "")
        link = item.findtext("link", "")
        pub = item.findtext("pubDate", "")
        desc = item.findtext("description", "")
        source_node = item.find("source")
        source = source_node.text if source_node is not None else ""
        cand = make_candidate(title, link, "GOOGLE_NEWS_RSS", pub, re.sub("<[^>]+>", " ", desc),
                              {"publisher_label": source})
        if cand:
            # Preserve original aggregator link. Publisher resolution may be needed by a researcher.
            out.append(cand)
    return out

def parse_feed(url, limit):
    text, _, final_url, _ = fetch_bytes(url, timeout=8, limit=2_000_000)
    root = ET.fromstring(text)
    out = []
    # RSS 2.0
    for item in root.findall(".//item")[:limit]:
        title = item.findtext("title", "")
        link = item.findtext("link", "")
        pub = item.findtext("pubDate", "") or item.findtext("{http://purl.org/dc/elements/1.1/}date", "")
        desc = item.findtext("description", "")
        c = make_candidate(title, link, "CONFIGURED_RSS", pub, re.sub("<[^>]+>", " ", desc),
                           {"feed_url": final_url})
        if c: out.append(c)
    # Atom
    ns = {"a": "http://www.w3.org/2005/Atom"}
    for entry in root.findall(".//a:entry", ns)[:limit]:
        title = entry.findtext("a:title", "", ns)
        link_node = entry.find("a:link", ns)
        link = link_node.attrib.get("href", "") if link_node is not None else ""
        pub = entry.findtext("a:published", "", ns) or entry.findtext("a:updated", "", ns)
        summary = entry.findtext("a:summary", "", ns) or entry.findtext("a:content", "", ns)
        c = make_candidate(title, link, "CONFIGURED_ATOM", pub, re.sub("<[^>]+>", " ", summary),
                           {"feed_url": final_url})
        if c: out.append(c)
    return out

def capture_article(candidate):
    # Google News article IDs are opaque aggregator links; avoid slow futile fetches.
    # Publisher-specific feeds/direct URLs should be used for actual article capture.
    host = urlparse(candidate.get("url", "")).hostname or ""
    if host.lower() == "news.google.com" and "/rss/articles/" in urlparse(candidate.get("url", "")).path:
        candidate["capture_status"] = "AGGREGATOR_LINK_ONLY"
        candidate["capture_note"] = "Resolve through a publisher-specific feed or direct public article URL."
        candidate["claim_verification_status"] = "NOT_VERIFIED"
        return candidate
    try:
        raw, ctype, final_url, status = fetch_bytes(candidate["url"])
        if "html" not in ctype.lower() and "<html" not in raw[:500].lower():
            candidate["capture_status"] = "FETCHED_NON_HTML"
            candidate["captured_text"] = raw[:5000]
            candidate["resolved_url"] = final_url
            candidate["http_status"] = status
            return candidate
        ex = TextExtractor()
        ex.feed(raw)
        body = re.sub(r"\s+", " ", " ".join(ex.text_parts)).strip()
        candidate["resolved_url"] = final_url
        candidate["http_status"] = status
        candidate["page_title"] = re.sub(r"\s+", " ", " ".join(ex.title_parts)).strip()
        candidate["page_description"] = ex.meta.get("description") or ex.meta.get("og:description") or ""
        candidate["page_published_at"] = (ex.meta.get("article:published_time") or ex.meta.get("datepublished")
            or ex.meta.get("date") or ex.meta.get("pubdate"))
        candidate["captured_text"] = body[:10000]
        candidate["capture_status"] = "FETCHED_TEXT" if len(body) >= 200 else "FETCHED_THIN_OR_BLOCKED"
        candidate["content_type"] = ctype
    except Exception as e:
        candidate["capture_status"] = "FETCH_FAILED"
        candidate["fetch_error"] = f"{type(e).__name__}: {str(e)[:300]}"
    # Explicitly do not mark factual claims as verified by a successful HTTP fetch.
    candidate["claim_verification_status"] = "NOT_VERIFIED"
    return candidate

def load_source_config(path):
    if not path: return {}
    return json.loads(Path(path).read_text(encoding="utf-8"))

def run_research(queries, persona_path=None, config_path=None, hours=72, limit=12, capture=True):
    started = now_utc()
    persona = get_persona(persona_path)
    config = load_source_config(config_path)
    if not queries:
        queries = config.get("default_queries", [])
    if not queries and persona:
        scope = persona.get("editorial_scope", {})
        queries = list(scope.get("allowlist", []))
    if not queries:
        raise ValueError("No search queries configured. Add persona editorial_scope.allowlist or pass --query.")
    all_candidates, errors = [], []
    providers = config.get("discovery_providers", ["gdelt", "google_news"])
    blocked_providers = set()
    for query in queries:
        for provider in providers:
            if provider in blocked_providers:
                continue
            try:
                if provider == "gdelt":
                    all_candidates.extend(gdelt_search(query, hours, limit))
                elif provider == "google_news":
                    all_candidates.extend(google_news_search(query, hours, limit))
                else:
                    errors.append({"provider": provider, "query": query, "error": "Unsupported provider"})
            except Exception as e:
                errors.append({"provider": provider, "query": query, "error": f"{type(e).__name__}: {str(e)[:300]}"})
                if "429" in str(e) or "Too Many Requests" in str(e):
                    blocked_providers.add(provider)
    for feed in config.get("rss_feeds", []):
        try:
            all_candidates.extend(parse_feed(feed, limit))
        except Exception as e:
            errors.append({"provider": "configured_feed", "url": feed, "error": f"{type(e).__name__}: {str(e)[:300]}"})
    # Dedupe by canonical URL, retain first metadata and alternate discovery trails.
    deduped = {}
    for c in all_candidates:
        key = canonical_url(c["url"])
        if key in deduped:
            trail = deduped[key].setdefault("also_discovered_by", [])
            if c["discovery_source"] not in trail: trail.append(c["discovery_source"])
            if c.get("snippet") and len(c["snippet"]) > len(deduped[key].get("snippet", "")):
                deduped[key]["snippet"] = c["snippet"]
        else:
            deduped[key] = c
    candidates = list(deduped.values())
    cutoff = started - dt.timedelta(hours=hours)
    fresh_candidates = []
    for c in candidates:
        pub = c.get("published_at")
        if not pub:
            c["freshness_status"] = "DATE_UNKNOWN"
            fresh_candidates.append(c)
            continue
        try:
            published_dt = dt.datetime.fromisoformat(pub.replace("Z", "+00:00"))
            if published_dt >= cutoff:
                c["freshness_status"] = "WITHIN_LOOKBACK"
                fresh_candidates.append(c)
        except Exception:
            c["freshness_status"] = "DATE_UNPARSEABLE"
            fresh_candidates.append(c)
    candidates = fresh_candidates
    # Stable heuristic ranking: freshness + source diversity. This is not a factuality score.
    def rank(c):
        pub = c.get("published_at")
        if not pub: return (1, c["title"].lower())
        try:
            age = (started - dt.datetime.fromisoformat(pub.replace("Z", "+00:00"))).total_seconds()
            return (max(0, age), c["title"].lower())
        except Exception: return (10**12, c["title"].lower())
    candidates.sort(key=rank)
    candidates = candidates[:max(1, min(limit * max(1, len(queries)) * len(providers), 100))]
    if capture:
        candidates = [capture_article(c) for c in candidates]
    return {
        "schema_version": 1, "runner_version": VERSION, "run_id": "research-" + started.strftime("%Y%m%dT%H%M%SZ"),
        "started_at": iso(started), "completed_at": iso(now_utc()), "persona_id": persona.get("persona_id"),
        "persona_status": persona.get("status", "NOT_CONFIGURED") if persona else "NOT_PROVIDED",
        "queries": queries, "providers_requested": providers, "lookback_hours": hours,
        "candidate_count": len(candidates), "candidates": candidates, "provider_errors": errors,
        "run_status": "RESULTS_FOUND" if candidates else ("PARTIAL_FAILURE" if errors else "NO_RESULTS"),
        "interpretation": "Search results are leads. Successful fetch means content was retrieved, not that its claims were verified.",
        "next_required_steps": ["rank against configured persona and public-interest criteria",
            "build claim ledger and counterevidence", "review source quality and independence",
            "draft channel variants", "run safety/platform-policy checks", "queue for human approval"]
    }

def main():
    ap = argparse.ArgumentParser(description="Discover and capture public online sources; no posting or remote scheduling.")
    ap.add_argument("--persona", help="Path to configured persona JSON")
    ap.add_argument("--config", help="Path to research source configuration JSON")
    ap.add_argument("--query", action="append", default=[], help="Topic/search query; repeatable")
    ap.add_argument("--hours", type=int, default=72, help="Discovery lookback window in hours (default: 72)")
    ap.add_argument("--limit", type=int, default=12, help="Maximum results per provider/query")
    ap.add_argument("--no-capture", action="store_true", help="Only discover links; do not fetch article pages")
    ap.add_argument("--output-dir", default="data/research_runs", help="Output directory, relative to current working directory")
    args = ap.parse_args()
    try:
        result = run_research(args.query, args.persona, args.config, max(1, args.hours),
                              max(1, min(args.limit, 50)), not args.no_capture)
    except Exception as e:
        print(json.dumps({"run_status":"CONFIGURATION_ERROR","error":f"{type(e).__name__}: {e}"}, indent=2))
        return 2
    outdir = Path(args.output_dir)
    outdir.mkdir(parents=True, exist_ok=True)
    outpath = outdir / (result["run_id"] + ".json")
    outpath.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"run_status":result["run_status"], "run_id":result["run_id"],
        "candidate_count":result["candidate_count"], "provider_errors":result["provider_errors"],
        "output_file":str(outpath.resolve()), "note":result["interpretation"]}, indent=2, ensure_ascii=False))
    return 0 if result["candidate_count"] else 1

if __name__ == "__main__":
    raise SystemExit(main())

