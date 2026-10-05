import base64
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace as NS
from bifrost.chatgpt_provider import ChatProvider, attachment, ProviderError
from bifrost.chatgpt_auth import validate_callback, require_plan_scope
from bifrost.chatgpt_mcp import authorize_tool

class Stream:
    def __init__(self, events): self.events=events; self.closed=False
    def __iter__(self): return iter(self.events)
    def close(self): self.closed=True

class ChatTests(unittest.TestCase):
    def provider(self, events):
        self.sent=[]
        self.stream=Stream(events)
        client=NS(responses=NS(create=lambda **kw: self.sent.append(kw) or self.stream))
        return ChatProvider(lambda: ("account-a", client), model="test")

    def test_streaming_context_and_completion(self):
        p=self.provider([NS(type="response.output_text.delta",delta="Hello"),
                         NS(type="response.completed")])
        deltas=[]
        self.assertEqual(p.chat("thread", "Hi", on_delta=deltas.append), "Hello")
        self.assertEqual(deltas, ["Hello"])
        p.chat("thread","Again")
        self.assertEqual(len(self.sent[1]["input"]), 3)
        self.assertFalse(self.sent[0]["store"])
        self.assertTrue(self.sent[0]["stream"])
        self.assertNotIn("previous_response_id",self.sent[0])
        self.assertTrue(self.stream.closed)

    def test_interrupted_stream_does_not_commit_history(self):
        p=self.provider([NS(type="response.output_text.delta",delta="partial")])
        with self.assertRaises(ProviderError): p.chat("thread","Hi")
        self.assertEqual(p.history, {})
        self.assertTrue(self.stream.closed)

    def test_failed_and_incomplete_streams(self):
        for kind in ["response.failed","response.incomplete","error"]:
            p=self.provider([NS(type=kind)])
            with self.assertRaises(ProviderError): p.chat("thread","Hi")
            self.assertEqual(p.history,{})

    def test_separate_threads(self):
        p=self.provider([NS(type="response.completed")])
        p.chat("one","private"); p.chat("two","other")
        self.assertEqual(len(self.sent[1]["input"]),1)

    def test_pdf_inline_without_upload(self):
        with tempfile.TemporaryDirectory() as d:
            path=Path(d)/"input.pdf"; path.write_bytes(b"%PDF-1.7 sample")
            item=attachment(path)
            self.assertEqual(item["type"],"input_file")
            self.assertEqual(item["filename"],"input.pdf")
            self.assertTrue(item["file_data"].startswith("data:application/pdf;base64,"))

    def test_image_inline(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"image.png"; p.write_bytes(b"\x89PNG\r\n\x1a\n")
            self.assertEqual(attachment(p)["type"],"input_image")

    def test_unknown_file_and_symlink_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"x.exe"; p.write_bytes(b"x")
            with self.assertRaises(ProviderError): attachment(p)
            q=Path(d)/"link.pdf"; q.symlink_to(p)
            with self.assertRaises(ProviderError): attachment(q)

    def test_invalid_prompt_rejected_without_request(self):
        p=self.provider([])
        for prompt in ["", " "*3, None]:
            with self.assertRaises(ProviderError): p.chat("thread",prompt)
        self.assertEqual(self.sent,[])

class AuthTests(unittest.TestCase):
    def test_dynamic_client_callback(self):
        result=validate_callback({"state":["s"],"code":["c"],"client_id":["oaiapp_x"]},"s",None)
        self.assertEqual(result,("c","oaiapp_x"))

    def test_rejects_wrong_state_missing_client_and_duplicates(self):
        for params in [{"state":["bad"],"code":["c"],"client_id":["x"]},
                       {"state":["s"],"code":["c"]},
                       {"state":["s","s"],"code":["c"],"client_id":["x"]},
                       {"state":["s"],"code":["c"],"client_id":["dynamic_agent_client"]}]:
            with self.assertRaises(ProviderError): validate_callback(params,"s",None)

    def test_reauthorization_cannot_swap_client(self):
        with self.assertRaises(ProviderError):
            validate_callback({"state":["s"],"code":["c"],"client_id":["new"]},"s","old")

    def test_denial_and_identity_only_are_not_ready(self):
        with self.assertRaises(ProviderError):
            validate_callback({"state":["s"],"error":["access_denied"]},"s",None)
        with self.assertRaises(ProviderError): require_plan_scope("openid email")
        require_plan_scope("openid resource.invoke chatgpt.tokens.use.direct")

class ToolTests(unittest.TestCase):
    def test_exact_authorization_required(self):
        for allowed in [set(), {"read_file"}]:
            with self.assertRaises(ProviderError): authorize_tool("execute_command",allowed)
        authorize_tool("read_file",{"read_file"})
