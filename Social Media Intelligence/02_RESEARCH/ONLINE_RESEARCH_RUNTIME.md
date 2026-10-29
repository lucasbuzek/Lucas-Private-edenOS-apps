# Online Research Runtime

## What now exists

`10_RUNTIME/research_runner.py` is a Python standard-library research discovery/capture prototype. It can:
- Search GDELT's public news index and Google News RSS for configured queries.
- Read explicitly configured public RSS/Atom feeds.
- Deduplicate links, preserve discovery provenance, publication dates, snippets and publisher metadata.
- Fetch publicly accessible article pages and capture text/metadata when available.
- Save a timestamped JSON research run with provider errors and unresolved verification status.

A successful fetch is not fact-checking. Every result remains `NOT_VERIFIED` until claim-level evidence review. Search coverage is not the whole internet; these providers are a starting layer and must be supplemented with domain-specific official records, scientific indexes, regulator feeds and other sources selected for the configured persona.

## First run

From Terminal on the Mac:

```sh
cd "$HOME/edenOS/Projects/Social Media Intelligence/10_RUNTIME"
python3 -m py_compile research_runner.py
python3 -m unittest discover -s . -p 'test_*.py' -v
python3 research_runner.py --query "your topic" --hours 72 --limit 12
```

Outputs are saved under `10_RUNTIME/data/research_runs/`. Use repeated `--query` flags for multiple search themes. Do not configure the template persona as if it were a real persona.

## Configured source feeds

Copy `02_RESEARCH/RESEARCH_SOURCE_CONFIG_TEMPLATE.json` to a versioned runtime configuration only after reviewing it. Add approved public RSS/Atom feed URLs to `rss_feeds`, and default search queries only after the real persona's scope is configured. Do not add credentials, cookies, or private URLs.

## Current limits

- GDELT and Google News RSS provide discovery coverage, not exhaustive global coverage.
- Google News may return aggregator URLs; publisher resolution and article access vary.
- Some sites block automated requests, require JavaScript, or restrict access. The runner records failure rather than bypassing access controls.
- The current runner captures source text but does not yet perform semantic claim verification or generate complete post copy.
- It does not connect social accounts, schedule posts remotely, submit posts, or retrieve account analytics.
- The ranking currently prioritizes recency. Persona relevance, source quality, diversity and public-interest scoring must be applied in the next orchestration layer.
- Recheck platform terms, robots/access restrictions and applicable law before expanding sources or running frequently.

