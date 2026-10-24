"""The native BIFROST Menu must not take control of independent peers.

These are source contracts. Actual Xcode compile and physical menu interaction
are independent acceptance gates.
"""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MENU=ROOT/"MenuController"

class PeerMenuSafetyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog=(MENU/"BifrostObservedPeerRegistry.swift").read_text()
        cls.peer=(MENU/"BifrostPeerMenu.swift").read_text()
        cls.menu=(MENU/"BIFROSTMenuControllerView.swift").read_text()
        cls.app=(MENU/"BIFROSTMenuControllerApp.swift").read_text()

    def test_exact_known_sources_not_arbitrary_launch_agents(self):
        for label in ("eden.bifrost.raven-bridge","org.eden.bifrost.core",
                      "org.eden.heimdall.headless"):
            self.assertIn(label,self.catalog)
        self.assertIn('arguments.contains(entry.expectedScript)',self.catalog)
        self.assertIn('plist["Label"] as? String == entry.id',self.catalog)

    def test_read_only_launchd_observation(self):
        self.assertIn('process.arguments = ["list"]',self.catalog)
        self.assertIn('executableURL = URL(fileURLWithPath: "/bin/launchctl")',self.catalog)
        for forbidden in ('"bootstrap"','"bootout"','"kickstart"','"start"','"stop"',
                          '"/bin/sh"','"sudo"','"killall"'):
            self.assertNotIn(forbidden,self.catalog)
        self.assertNotIn('process.arguments',self.peer)

    def test_peer_controls_never_exposed_as_granted(self):
        self.assertIn("let controllable = false",self.catalog)
        self.assertIn("Start/Stop unavailable · owner approval required",self.peer)
        self.assertIn("Application health and peer controls NOT verified",self.catalog)
        self.assertIn("Process state is not service health",self.peer)

    def test_observations_do_not_claim_health(self):
        self.assertIn("Process observed · health unverified",self.catalog)
        self.assertIn("Configured · not loaded",self.catalog)
        self.assertIn("Observation stale · refresh to inspect",self.peer)
        self.assertIn("hasFreshObservation",self.catalog)
        self.assertIn("<= 45",self.catalog)

    def test_original_bifrost_controls_and_identity_retained(self):
        for text in ("Open BIFROST App","Start Headless","Stop Headless…",
                     "Keep Awake","Open Local Dashboard",
                     "Quit Menu Controller · Keep Headless"):
            self.assertIn(text,self.menu)
        self.assertIn("BifrostBridgeSymbol(width: 24, height: 18)",self.app)
        self.assertIn("MenuBarExtra",self.app)
        self.assertIn("BIFROSTMenuControllerApp",self.app)
        self.assertIn("BIFROST · CONNECT · KEEP · RESOLVE",self.menu)

    def test_interface_levels_are_real(self):
        for level in ("Simple","Advanced","Expert"):
            self.assertIn('"'+level+'"',self.menu)
        self.assertIn('if menuLevel != "Simple"',self.menu)
        self.assertIn('expert: menuLevel == "Expert"',self.menu)
        self.assertIn('Text("launchd · " + peer.id)',self.peer)

    def test_bridge_pulse_is_low_cadence_and_respects_accessibility(self):
        self.assertIn(".accessibilityReduceMotion",self.app)
        self.assertIn("isLowPowerModeEnabled",self.app)
        self.assertIn("TimelineView(.periodic(from: .now, by: 3))",self.app)
        self.assertIn("headless.isRunning",self.app)
        self.assertIn("animateBridge",self.app)

    def test_other_peer_discovery_on_demand(self):
        self.assertIn('if menuLevel != "Simple" { peers.refresh() }',self.menu)
        self.assertNotIn("Timer.scheduledTimer",self.catalog)
        self.assertNotIn("DispatchSourceTimer",self.catalog)
        self.assertNotIn("start()",self.catalog)
        self.assertNotIn("stop()",self.catalog)

if __name__=="__main__":
    unittest.main()

