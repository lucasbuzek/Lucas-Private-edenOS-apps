"""Offline contract tests for consent-gated local agent; no network, accounts or devices."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE=Path(__file__).resolve().parents[1]/"thembicouncil_agent.py"
spec=importlib.util.spec_from_file_location("agent",MODULE)
agent=importlib.util.module_from_spec(spec)
spec.loader.exec_module(agent)

class AgentLocalContract(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.root=Path(self.tmp.name).resolve()
        self.cfg={"roots":[self.root],"allowed_commands":["whoami","hostname","date","uname","uptime","ipconfig","systeminfo","tasklist"]}
    def tearDown(self):
        self.tmp.cleanup()
    def job(self,name,**args):
        return {"action":name,"args":args}
    def test_write_read_list(self):
        p=self.root/"demo.txt"
        result=agent.execute(self.job("files.write",path=str(p),content="Council data",overwrite=False),self.cfg)
        self.assertEqual(result["bytes_written"],12)
        text=agent.execute(self.job("files.read",path=str(p)),self.cfg)
        self.assertEqual(text["content"],"Council data")
        listing=agent.execute(self.job("files.list",path=str(self.root)),self.cfg)
        self.assertIn("demo.txt",[x["name"] for x in listing["entries"]])
    def test_cannot_overwrite_without_explicit_flag(self):
        p=self.root/"existing.txt";p.write_text("original",encoding="utf-8")
        with self.assertRaises(FileExistsError):
            agent.execute(self.job("files.write",path=str(p),content="secret",overwrite=False),self.cfg)
        self.assertEqual(p.read_text(encoding="utf-8"),"original")
    def test_outside_root_denied(self):
        with tempfile.TemporaryDirectory() as other:
            outside=Path(other).resolve()/"hello.txt"
            with self.assertRaises(PermissionError):
                agent.execute(self.job("files.write",path=str(outside),content="bad"),self.cfg)
    def test_disallowed_executable_denied(self):
        with self.assertRaises(PermissionError):
            agent.execute(self.job("terminal.exec",command="python -c print(1)"),self.cfg)
    def test_unknown_actions_denied(self):
        with self.assertRaises(ValueError):
            agent.execute(self.job("unrecognized",path=str(self.root)),self.cfg)
    def test_symlink_escape_denied(self):
        with tempfile.TemporaryDirectory() as other:
            link=self.root/"escape"
            try: link.symlink_to(Path(other),target_is_directory=True)
            except (OSError,NotImplementedError): self.skipTest("Symlinks not permitted on this host")
            with self.assertRaises(PermissionError):
                agent.execute(self.job("files.write",path=str(link/"x.txt"),content="no"),self.cfg)
if __name__=="__main__":unittest.main()
