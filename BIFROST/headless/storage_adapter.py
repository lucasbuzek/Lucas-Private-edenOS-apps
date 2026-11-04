"""Optional BIFROST Files & Storage metadata adapter for the existing Headless.

Only called from an authenticated, loopback Headless route. This is NOT a
new service or storage runtime: load the existing BIFROST/core module once
per explicit request, from the bundled core/ resource or source tree.
"""
import importlib.util
import pathlib
import stat

BASE = pathlib.Path(__file__).resolve().parent
CORE_CANDIDATES = (BASE / "storage_capability.py", BASE.parent / "core" / "storage_capability.py")


class StorageUnavailable(RuntimeError):
    pass


def _core():
    for file in CORE_CANDIDATES:
        try:
            info = file.lstat()
        except FileNotFoundError:
            continue
        if not stat.S_ISREG(info.st_mode) or info.st_size > 262144:
            raise StorageUnavailable("Untrusted BIFROST Files & Storage module")
        spec = importlib.util.spec_from_file_location("bifrost_storage_capability", file)
        if not spec or not spec.loader:
            raise StorageUnavailable("BIFROST Files & Storage source not loadable")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    raise StorageUnavailable("BIFROST Files & Storage core is unavailable")


def catalog():
    module = _core()
    return {"schema": module.SCHEMA,
            "authority": "BIFROSTcore",
            "execution": "local-metadata-read-only",
            "capability": module.status(),
            "providers": module.providers(),
            "installedConnector": False,
            "chatgptBridge": "NOT_CONNECTED"}


def accounts():
    module = _core()
    # Account list ONLY after existing Headless local session authentication.
    # Never expose provider OAuth tokens or passwords, never make network calls.
    return {"schema": module.SCHEMA,
            "source": "local-config-metadata",
            "authorizedByThisModule": False,
            "accounts": module.accounts()}


def preview(name: str, *, folder: str = "",
            read_remote: bool = False) -> dict:
    """One profile-bound metadata preview, behind existing Headless auth.

    No arbitrary local paths or account remotes are accepted from the HTTP
    request. Saved named profiles are the only possible browse boundaries.
    """
    candidates = (
        BASE / "storage_preview.py",
        BASE.parent / "core" / "storage_preview.py",
    )
    for file in candidates:
        try:
            info = file.lstat()
        except FileNotFoundError:
            continue
        if not stat.S_ISREG(info.st_mode) or info.st_size > 262144:
            raise StorageUnavailable("Untrusted storage preview module")
        spec = importlib.util.spec_from_file_location("bifrost_storage_preview", file)
        if spec is None or spec.loader is None:
            raise StorageUnavailable("Storage preview source not loadable")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module.preview(
            name, folder=folder, read_remote=read_remote,
            remote_reader=module.rclone_metadata_reader if read_remote else None
        )
    raise StorageUnavailable("Storage preview module not installed")


def profiles():
    """Display fields only; no account binding, paths or credentials."""
    module = _core()
    result = []
    for item in module.profiles():
        if not isinstance(item, dict) or not isinstance(item.get('name'), str):
            raise StorageUnavailable('Malformed storage profile')
        result.append({'name': item['name'], 'provider': str(item.get('provider', 'unknown'))})
    return {'profiles': result, 'execution': 'local-metadata-read-only'}
