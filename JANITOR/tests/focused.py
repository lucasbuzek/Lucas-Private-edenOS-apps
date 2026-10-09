"""The requested focused gate; controlled fixtures only."""
import subprocess
import sys
import unittest
from test_janitor import ROOT, JanitorTests

for path in [ROOT / 'JANITOR.command', ROOT / 'core/janitor-macos.sh']:
    subprocess.run(['/bin/bash', '-n', str(path)], check=True)
print('Bash syntax: PASS', flush=True)
launcher = subprocess.check_output(['/bin/bash', str(ROOT / 'JANITOR.command'), '--version'], text=True).strip()
core = subprocess.check_output(['/bin/bash', str(ROOT / 'core/janitor-macos.sh'), '--version'], text=True).strip()
assert launcher == core
print('Launcher/core version match: PASS (' + core + ')', flush=True)
names = [
    'test_quick_full_developer_workflows_remain_separate',
    'test_developer_quarantine_preserves_first_latest',
    'test_manual_quarantine_restore_round_trip',
    'test_missing_manual_quarantine_is_tolerated',
    'test_known_folders_deferred_without_visible_icloud',
    'test_legacy_provider_root_deferred',
    'test_provider_descendant_pruned_from_duplicates',
    'test_top_level_modes_and_protected_process_group',
    'test_startup_inventory_groups_by_declared_executable',
]
result = unittest.TextTestRunner(stream=sys.stdout, verbosity=2).run(unittest.TestSuite(JanitorTests(n) for n in names))
sys.exit(0 if result.wasSuccessful() else 1)
