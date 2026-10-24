"""BIFROSTcore ZERO network resilience tests; no real network mutations."""
from pathlib import Path
import socket
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import bifrost_network_resilience as net


class NetworkResilienceTests(unittest.TestCase):
    def test_passive_status_never_contacts_external_host(self):
        with mock.patch.object(net.socket, "create_connection") as outbound:
            with mock.patch.object(net, "route_interface", return_value="en0"):
                report = net.sample()
        outbound.assert_not_called()
        self.assertEqual(report["endpointTCP"], "NOT_CHECKED")
        self.assertFalse(report["networkChangeExecuted"])
        self.assertFalse(report["wifiSSIDRead"])

    def test_fixed_host_requires_explicit_approval(self):
        with mock.patch.object(net.socket, "create_connection") as outbound:
            for target in ("rdc", "apple", "attacker", "", None):
                if target is None:
                    continue
                with self.subTest(target=target):
                    with self.assertRaises(net.ResilienceError):
                        net.sample(target, approved=False)
            with self.assertRaises(net.ResilienceError):
                net.sample("arbitrary", approved=True)
        outbound.assert_not_called()

    def test_no_default_route_is_not_false_reachability(self):
        with mock.patch.object(net.socket, "create_connection") as outbound:
            report = net.sample("rdc", approved=True, interface=lambda: None)
        self.assertEqual(report["endpointTCP"], "NO_DEFAULT_ROUTE")
        outbound.assert_not_called()

    def test_tcp_success_is_not_service_authentication(self):
        fake = mock.Mock()
        report = net.sample("rdc", approved=True,
                            interface=lambda: "en0",
                            connect=lambda addr, timeout: fake)
        self.assertEqual(report["endpointTCP"], "REACHABLE_ON_THIS_PROBE")
        self.assertEqual(report["target"], "rdc")
        self.assertFalse(report["providerAuthenticated"])
        self.assertFalse(report["networkChangeExecuted"])
        fake.close.assert_called_once()

    def test_tcp_failure_is_bounded_to_one_selected_endpoint(self):
        def failed(addr, timeout):
            self.assertEqual(addr, ("www.apple.com", 443))
            self.assertEqual(timeout, 3)
            raise TimeoutError("not reachable")
        report = net.sample("apple", approved=True,
                            interface=lambda: "en0", connect=failed)
        self.assertEqual(report["endpointTCP"], "UNREACHABLE_ON_THIS_PROBE")

    def test_native_route_filters_unknown_interfaces(self):
        def runner(argv, **kw):
            return subprocess.CompletedProcess(argv, 0,
                "route to: default\ninterface: en0\n", "")
        self.assertEqual(net.route_interface(run=runner), "en0")
        def vpn(argv, **kw):
            return subprocess.CompletedProcess(argv, 0,
                "interface: utun4\n", "")
        self.assertIsNone(net.route_interface(run=vpn))

    def test_native_route_timeout_fails_closed(self):
        with mock.patch.object(net.subprocess, "run", side_effect=subprocess.TimeoutExpired("route", 4)):
            self.assertIsNone(net.route_interface())

    def test_policy_requires_three_consecutive_failures(self):
        policy = net.FailurePolicy()
        failure = {"routeInterface": "en0", "endpointTCP": "UNREACHABLE_ON_THIS_PROBE"}
        self.assertEqual(policy.update(failure, 1), "RETRY_OBSERVATION")
        self.assertEqual(policy.update(failure, 2), "RETRY_OBSERVATION")
        self.assertEqual(policy.update(failure, 3), "OWNER_FALLBACK_RECOMMENDED")
        self.assertEqual(policy.update(failure, 4), "DEGRADED_COOLDOWN")
        self.assertEqual(policy.update(failure, 400), "OWNER_FALLBACK_RECOMMENDED")

    def test_recovery_clears_failure_and_waits_for_new_streak(self):
        policy = net.FailurePolicy()
        failed = {"routeInterface": "en0", "endpointTCP": "NO_DEFAULT_ROUTE"}
        passed = {"routeInterface": "en0", "endpointTCP": "REACHABLE_ON_THIS_PROBE"}
        policy.update(failed, 1)
        policy.update(failed, 2)
        self.assertEqual(policy.update(passed, 3), "OBSERVED_REACHABLE")
        self.assertEqual(policy.update(failed, 4), "RETRY_OBSERVATION")

    def test_interface_change_resets_failure_streak(self):
        policy = net.FailurePolicy()
        failed = {"routeInterface": "en0", "endpointTCP": "UNREACHABLE_ON_THIS_PROBE"}
        for t in (1, 2):
            policy.update(failed, t)
        self.assertEqual(policy.update(
            {"routeInterface": "en1", "endpointTCP": "NO_DEFAULT_ROUTE"}, 3),
            "RETRY_OBSERVATION")

    def test_unknown_state_does_not_trigger_fallback(self):
        policy = net.FailurePolicy()
        for t in (0, 1, 2, 3):
            self.assertEqual(policy.update(
                {"routeInterface": None, "endpointTCP": "NOT_CHECKED"}, t),
                "UNKNOWN_NO_PROBE")

    def test_monitor_requires_selected_target_and_explicit_consent(self):
        with mock.patch.object(net, "sample") as probe:
            for args in ((60, "rdc", False), (60, "unsafe", True), (2, "rdc", True)):
                with self.subTest(args=args), self.assertRaises(net.ResilienceError):
                    net.watch(interval=args[0], target=args[1], approved=args[2],
                              max_checks=1)
        probe.assert_not_called()

    def test_monitor_bounded_only_uses_one_explicit_target(self):
        calls = []
        waits = []
        states = iter(["UNREACHABLE_ON_THIS_PROBE",
                       "REACHABLE_ON_THIS_PROBE"])
        def reader(target, approved):
            calls.append((target, approved))
            return {"routeInterface": "en0", "endpointTCP": next(states)}
        lines = []
        result = net.watch(interval=30, target="rdc", approved=True,
                           read=reader, output=lines.append,
                           wait=waits.append, clock=lambda: 20,
                           ask=lambda msg: "", max_checks=2)
        self.assertEqual(result, 2)
        self.assertEqual(calls, [("rdc", True), ("rdc", True)])
        self.assertEqual(waits, [30])
        self.assertIn("OBSERVED_REACHABLE", lines[-1])

    def test_repeated_failures_do_not_switch_network(self):
        output = []
        def read(target, approved):
            return {"routeInterface": "en0",
                    "endpointTCP": "UNREACHABLE_ON_THIS_PROBE"}
        with mock.patch.object(net, "open_wifi_settings") as settings:
            net.watch(interval=15, target="apple", approved=True,
                      read=read, wait=lambda _: None,
                      clock=iter((1, 2, 3)).__next__,
                      output=output.append, ask=lambda _: "",
                      max_checks=3)
        settings.assert_not_called()
        self.assertTrue(any("OWNER_FALLBACK_RECOMMENDED" in s for s in output))

    def test_settings_handoff_needs_explicit_authorization(self):
        with mock.patch.object(net.subprocess, "run") as task:
            with self.assertRaises(net.ResilienceError):
                net.open_wifi_settings(approved=False)
        task.assert_not_called()
        completed = subprocess.CompletedProcess(["open"], 0, "", "")
        with mock.patch.object(net.subprocess, "run", return_value=completed) as task:
            self.assertEqual(net.open_wifi_settings(approved=True),
                             "SYSTEM_SETTINGS_OPEN_REQUESTED_NOT_NETWORK_SWITCHED")
        task.assert_called_once()
        self.assertEqual(task.call_args.args[0], ["/usr/bin/open", "-a", "System Settings"])

    def test_no_silent_background_monitor_through_cli(self):
        with mock.patch.object(net.sys.stdin, "isatty", return_value=False), \
             mock.patch.object(net, "watch") as monitor:
            self.assertEqual(net.main(["watch", "--target", "rdc", "--approve-probe"]), 2)
        monitor.assert_not_called()

    def test_all_targets_are_fixed_https_port_destinations(self):
        self.assertEqual(set(net.CHECKS), {"rdc", "apple"})
        self.assertTrue(all(p == 443 for _, p in net.CHECKS.values()))
        self.assertFalse(any("password" in x for x in net.CHECKS))

    def test_denied_main_probe_has_no_network_side_effect(self):
        with mock.patch.object(net.socket, "create_connection") as outbound:
            self.assertEqual(net.main(["check", "--target", "rdc"]), 2)
        outbound.assert_not_called()


if __name__ == "__main__":
    unittest.main()
