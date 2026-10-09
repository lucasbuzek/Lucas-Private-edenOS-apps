"""Bounded performance evidence using synthetic files only."""
import json
import time
from test_janitor import JanitorTests

fixture = JanitorTests()
fixture.setUp()
results = []
try:
    for n in range(6000):
        fixture.file(f'Downloads/bucket-{n // 100}/file-{n}.txt', b'fixture\n')
    for n in range(1, 5):
        fixture.file(f'Downloads/Fixture_BUILD{n}/build', b'build\n')
    fixture.file('Library/Caches/pip/cache', b'cache' * 2048)
    sparse = fixture.file('Movies/large-sparse.mov')
    with sparse.open('r+b') as stream:
        stream.truncate(1024 * 1024 * 1024)
    cases = [
        ('Quick', 'quick_scan', 'q\n', 25),
        ('Full', 'full_scan', 'b\n', 30),
        ('Developer Quick', 'developer_quick_scan', 'b\n', 30),
        ('Project Discovery', 'project_discovery', '\n', 20),
        ('Build/Dependency', 'large_dev', '\n', 30),
        ('Quick forced total budget', 'JANITOR_QUICK_TOTAL_TIMEOUT=1 quick_scan', 'q\n', 8),
        ('Whole process-group timeout', 'slow(){ sleep 10; }; run_deadline 1 "$CACHE_DIR/out" "$CACHE_DIR/err" slow', '', 5),
    ]
    for name, code, input_text, wall_limit in cases:
        start = time.monotonic()
        result = fixture.shell(code, input=input_text, timeout=wall_limit)
        elapsed = time.monotonic() - start
        expected = 124 if name == 'Whole process-group timeout' else 0
        record = dict(name=name, seconds=round(elapsed, 3), returncode=result.returncode,
                      wall_limit=wall_limit, partial='PARTIAL' in (result.stdout + result.stderr),
                      passed=result.returncode == expected and elapsed < wall_limit,
                      stdout=result.stdout, stderr=result.stderr)
        if name == 'Quick forced total budget':
            record['passed'] = record['passed'] and record['partial']
        results.append(record)
    assert all(x['passed'] for x in results), 'Performance gate failed'
finally:
    fixture.tearDown()
    print(json.dumps(dict(fixture_files=6000, personal_data_scanned=False, results=results), indent=2))
