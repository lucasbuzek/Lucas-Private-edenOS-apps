"""
IRIS provider adapter.

Replace `generate_image()` with your actual image-generation provider call.
Keep this file provider-specific; the batch runner itself should remain provider-agnostic.

The function must complete one image before returning.
That preserves IRIS sequential batch semantics.
"""

from pathlib import Path
from typing import List, Dict, Any

def generate_image(
    prompt: str,
    output_path: Path,
    reference_images: List[str] | None = None,
    metadata: Dict[str, Any] | None = None,
) -> Path:
    raise NotImplementedError(
        "Connect your image generation provider in runner/provider_adapter.py"
    )
