"""End-to-end generation of a structurally valid, source-grounded editable DOCX."""
import tempfile
import sys
import zipfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from themis.store import ThemisStore
from themis.documents import create_dossier
from docx import Document
with tempfile.TemporaryDirectory() as tmp:
    db = ThemisStore(Path(tmp) / "records.json")
    matter = db.add("matter", "Electrical installation enquiry", {"jurisdiction": "South Africa", "objective": "Review an installation matter"}, {"source": "owner-supplied brief"})
    db.add("obligation", "Verify registered person", {"matter_id": matter["id"], "status": "UNKNOWN", "law_effective_date": "NOT VERIFIED"}, {"source": "user instruction", "citation": "not supplied"})
    db.add("evidence", "Inspection record", {"matter_id": matter["id"], "document_ref": "inspection-log-1"}, {"source": "user-provided register"})
    db.add("obligation", "Unrelated private matter", {"matter_id": "other-matter", "notes": "SECRET-UNRELATED"})
    output = Path(tmp) / "dossier.docx"
    receipt = create_dossier(db, matter["id"], output)
    assert receipt["format"] == "docx" and receipt["linked_records"] == 2
    with zipfile.ZipFile(output) as z:
        assert z.testzip() is None
        assert "word/document.xml" in z.namelist()
    doc = Document(output)
    all_text = "\n".join([p.text for p in doc.paragraphs] + [c.text for t in doc.tables for row in t.rows for c in row.cells])
    for expected in ("Electrical installation enquiry", "South Africa", "Verify registered person", "Inspection record", "CONTROLLED DRAFT"):
        assert expected in all_text, expected
    assert "SECRET-UNRELATED" not in all_text
    assert "Not verified" not in all_text
print("PASS: native editable DOCX, source traceability, scoped matter records, no cross-matter leak, draft controls")
