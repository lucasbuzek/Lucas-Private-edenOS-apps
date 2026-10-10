import io
import json
import subprocess
import unittest
from unittest import mock

import bifrostctl


class Response:
    def __enter__(self): return self
    def __exit__(self, *args): return False
    def read(self): return json.dumps({"node_credential": "fake-node-credential"}).encode()


class EnrollTests(unittest.TestCase):
    @mock.patch.object(bifrostctl, "_get", return_value=None)
    @mock.patch.object(bifrostctl.subprocess, "run")
    def test_token_is_posted_from_stdin_and_credential_not_printed(self, run, _get):
        captured = {}
        def opener(request, timeout):
            captured["url"], captured["body"], captured["timeout"] = request.full_url, request.data, timeout
            return Response()
        output = io.StringIO()
        with mock.patch("sys.stdout", output):
            bifrostctl.enroll(io.StringIO("fake-one-time-token\n"), opener=opener)
        self.assertTrue(captured["url"].endswith("/api/node/enroll"))
        self.assertEqual(json.loads(captured["body"])["enrollment_token"], "fake-one-time-token")
        self.assertNotIn("fake-one-time-token", output.getvalue())
        self.assertNotIn("fake-node-credential", output.getvalue())
        self.assertIn("fake-node-credential", run.call_args.args[0])

    @mock.patch.object(bifrostctl, "_get", return_value="existing-fake")
    @mock.patch.object(bifrostctl.subprocess, "run")
    def test_existing_credential_requires_confirmation_before_http(self, run, _get):
        opener = mock.Mock()
        with self.assertRaises(SystemExit):
            bifrostctl.enroll(io.StringIO("fake-token\n"), input_fn=lambda _: "n", opener=opener)
        opener.assert_not_called()
        run.assert_not_called()


if __name__ == "__main__": unittest.main()
