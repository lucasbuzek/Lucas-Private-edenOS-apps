"""Task 1 capability provider. No ChatGPT desktop app or hosted MCP dependency."""
from __future__ import annotations
import base64
import copy
import json
import os
import stat
import threading
from pathlib import Path

class ProviderError(Exception):
    """Only stable, non-secret error codes cross the host boundary."""
    pass

MAX_FILE = 10 * 1024 * 1024
MAX_CONTEXT = 64 * 1024 * 1024
MIMES = {".pdf":"application/pdf", ".txt":"text/plain", ".md":"text/markdown",
         ".csv":"text/csv", ".json":"application/json",
         ".png":"image/png", ".jpg":"image/jpeg", ".jpeg":"image/jpeg",
         ".webp":"image/webp"}

def attachment(path):
    path = Path(path)
    mime = MIMES.get(path.suffix.lower())
    if not mime: raise ProviderError("unsupported_file")
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, "rb") as f:
            info = os.fstat(f.fileno())
            if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_FILE:
                raise ProviderError("file_too_large_or_not_regular")
            data = f.read(MAX_FILE + 1)
    except OSError as e:
        raise ProviderError("file_unavailable") from e
    if len(data) > MAX_FILE: raise ProviderError("file_too_large")
    encoded = f"data:{mime};base64," + base64.b64encode(data).decode("ascii")
    if mime.startswith("image/"): return {"type":"input_image","image_url":encoded}
    return {"type":"input_file","filename":path.name,"file_data":encoded}

class ChatProvider:
    def __init__(self, client_for_account, model=None):
        self.client_for_account = client_for_account
        self.model = model
        self.history = {}
        self._lock = threading.Lock()

    def forget(self, thread=None):
        with self._lock:
            if thread is None: self.history.clear()
            else:
                for key in list(self.history):
                    if key[1] == thread: del self.history[key]

    def chat(self, thread, prompt, files=(), on_delta=lambda text: None):
        if not isinstance(prompt,str) or not prompt.strip() or len(prompt)>100000:
            raise ProviderError("invalid_prompt")
        if not isinstance(thread,str) or not thread or len(thread)>200:
            raise ProviderError("invalid_thread")
        if len(files)>4: raise ProviderError("too_many_files")
        if not self._lock.acquire(blocking=False): raise ProviderError("request_busy")
        client = None
        try:
            account, client = self.client_for_account()
            model = self.model
            if model is None:
                catalog = client.get("/models",cast_to=dict)
                visible = [m["slug"] for m in catalog.get("models",[]) if m.get("visibility")=="list"]
                if not visible: raise ProviderError("no_available_model")
                model = visible[0]
            content = [{"type":"input_text","text":prompt}] + [attachment(p) for p in files]
            user = {"role":"user","content":content}
            key = (account,thread)
            context = copy.deepcopy(self.history.get(key,[])) + [user]
            if len(json.dumps(context).encode())>MAX_CONTEXT: raise ProviderError("context_limit")
            try:
                stream = client.responses.create(model=model,input=context,store=False,stream=True)
            except Exception as error:
                # SDK error text may contain private input; expose only a known code.
                if getattr(error, "code", None) == "context_length_exceeded":
                    raise ProviderError("context_limit") from None
                raise
            text = ""
            output = None
            completed = False
            try:
                for event in stream:
                    if event.type=="response.output_text.delta":
                        text += event.delta
                        if len(text)>8*1024*1024: raise ProviderError("response_too_large")
                        on_delta(event.delta)
                    elif event.type in {"response.failed","response.incomplete","error"}:
                        raise ProviderError(event.type)
                    elif event.type=="response.completed":
                        completed=True
                        response = getattr(event,"response",None)
                        if response is not None:
                            output = [item.model_dump(mode="json",exclude_none=True) for item in response.output]
                        break
            finally:
                stream.close()
            if not completed: raise ProviderError("stream_interrupted")
            # Retain reasoning/tool context from the completed response when supplied.
            self.history[key] = context + (output if output is not None else [{"role":"assistant","content":text}])
            return text
        finally:
            if client is not None and hasattr(client, "close"):
                try: client.close()
                except Exception: pass
            self._lock.release()
