"""DeLorean client-neutral platform capability description (not an installed-client registry).

This report is intentionally honest: its matrices describe targets and source
candidates; they do NOT assert real devices or connected third-party tools.
"""
from __future__ import annotations
import platform

TARGETS = {
    'macos': ('desktop-native-and-mcp', 'swiftui-source-only'),
    'windows': ('desktop-native-and-mcp', 'not-built'),
    'linux': ('desktop-native-and-mcp', 'python-mcp-fixture-tested'),
    'ios': ('mobile-native-companion', 'swiftui-read-only-source-only'),
    'ipados': ('mobile-native-companion', 'swiftui-read-only-source-only'),
    'android': ('mobile-native-companion', 'not-built'),
    'web': ('web-pwa-and-mcp-app', 'read-only-html-candidate'),
}
AGENT_SURFACES = ('chatgpt','claude','codex','gemini','other-mcp-agent')
CONNECTOR_CAPABILITIES = ('github-revision-history','cloud-provider-revisions',
                          'authorized-device-executor','encrypted-backup-engine',
                          'optional-penelope-references')


def platform_matrix() -> dict:
    host = platform.system()
    return {
        'schema':'eden.delorean.client-target-matrix.v1',
        'product':'DeLorean TimeMachine',
        'architecture':'multi-agent-plugin-and-native-client-family',
        'executor_os_observed':host,
        'agent_surfaces_targets':list(AGENT_SURFACES),
        'native_platforms': {key:{'role':role,'evidence':evidence,'installed_verified':False}
                             for key,(role,evidence) in TARGETS.items()},
        'connector_bridge_capabilities':list(CONNECTOR_CAPABILITIES),
        'connected_connector_instances_verified_here':[],
        'remote_mcp_host_connected_verified':False,
        'exclusive_chatgpt_dependency':False,
        'exclusive_macos_dependency':False,
        'penelope_mandatory':False,
        'cloud_mandatory':False,
        'note':'Targets and source evidence, not a device-install or backup/restore acceptance report.'
    }
