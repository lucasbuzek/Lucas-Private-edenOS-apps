"""Source-grounded editable DOCX matter dossier from the existing THEMIS record store.

Uses python-docx, an existing external open-source document engine.
Never invents legal rules, approvals, evidence, parties, or effective dates.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

from .store import ThemisStore

SECTIONS = [
    ("party", "Parties and authorities"),
    ("agreement", "Contracts and agreements"),
    ("clause", "Clauses and definitions"),
    ("obligation", "Rights and obligations"),
    ("jurisdiction", "Jurisdiction and applicable law"),
    ("research", "Legal research and sources"),
    ("evidence", "Evidence and provenance"),
    ("deadline", "Deadlines and temporal requirements"),
    ("correspondence", "Correspondence and notices"),
    ("approval", "Reviews and approvals"),
    ("version", "Versions and revisions"),
]


def _value(value):
    if value is None or value == "":
        return "UNKNOWN / NOT PROVIDED"
    if isinstance(value, (list, dict)):
        return json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True)
    return str(value)


def _table(doc, rows):
    table = doc.add_table(rows=0, cols=2)
    table.style = "Light Shading Accent 1"
    for label, value in rows:
        cells = table.add_row().cells
        cells[0].text = str(label)
        cells[1].text = _value(value)
    return table


def create_dossier(store, matter_id, output_path, *, include_unlinked=False):
    """Render an editable Word dossier for one existing matter; returns a receipt.

    Linked records must explicitly carry fields.matter_id == matter_id. The
    optional include_unlinked switch is for a knowingly scoped standalone store
    and is off by default to avoid cross-matter disclosure.
    """
    from docx import Document
    from docx.shared import Cm, Pt
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    matter = store.get(matter_id)
    if not matter or matter.get("kind") != "matter":
        raise ValueError("An existing THEMIS matter ID is required")
    others = [rec for rec in store.list() if rec["id"] != matter_id and
              (rec.get("fields", {}).get("matter_id") == matter_id or
               (include_unlinked and not rec.get("fields", {}).get("matter_id")))]
    doc = Document()
    doc.core_properties.title = "THEMIS — " + matter["title"]
    doc.core_properties.subject = "Source-grounded legal matter dossier"
    doc.core_properties.author = "THEMIS"
    sec = doc.sections[0]
    sec.top_margin = sec.bottom_margin = Cm(2.2)
    sec.left_margin = sec.right_margin = Cm(2.3)
    normal = doc.styles["Normal"]
    normal.font.name = "Aptos"
    normal.font.size = Pt(10)
    top = doc.add_paragraph("THEMIS | LEGAL MATTER DOSSIER")
    top.alignment = WD_ALIGN_PARAGRAPH.CENTER
    top.style = "Subtitle"
    doc.add_heading(matter["title"], 0)
    doc.add_paragraph("CONTROLLED DRAFT — NOT APPROVED FOR FILING, SERVICE OR LEGAL RELIANCE.")
    doc.add_paragraph("This document reproduces available matter records. Unknowns and legal assertions require source verification, competent review and appropriate approval. It does not certify compliance or issue legal advice.")
    doc.add_heading("1. Matter identification and scope", 1)
    _table(doc, [
        ("Matter ID", matter["id"]), ("Title", matter["title"]),
        ("Jurisdiction", matter.get("fields", {}).get("jurisdiction")),
        ("Objective", matter.get("fields", {}).get("objective")),
        ("Document status", "CONTROLLED DRAFT — NOT APPROVED"),
        ("Record revision", matter.get("revision", "Original local record")),
        ("Created", matter.get("created_at")),
        ("Last updated", matter.get("updated_at")),
    ])
    doc.add_heading("2. Matter facts, assumptions and open questions", 1)
    fields = matter.get("fields") or {}
    if fields:
        _table(doc, sorted(fields.items()))
    else:
        doc.add_paragraph("No verified matter facts have been supplied.")
    doc.add_heading("3. Original matter source", 1)
    _table(doc, sorted((matter.get("provenance") or {}).items()) or [("Source", None)])
    for index, (kind, title) in enumerate(SECTIONS, 4):
        doc.add_heading(str(index) + ". " + title, 1)
        records = [rec for rec in others if rec.get("kind") == kind]
        if not records:
            doc.add_paragraph("No source-grounded " + kind + " records have been linked to this matter.")
            continue
        for record in records:
            doc.add_heading(record["title"], 2)
            info = [("Record ID", record["id"]),
                    ("Last updated", record.get("updated_at"))]
            info.extend(sorted((record.get("fields") or {}).items()))
            info.extend(("Source: " + str(k), v) for k, v in sorted((record.get("provenance") or {}).items()))
            _table(doc, info)
    doc.add_heading(str(len(SECTIONS) + 4) + ". Verification and approval gates", 1)
    doc.add_paragraph("The presence of a record is not evidence of legal correctness, professional approval, signed authorization or action execution. Identify each missing source, law effective date, competent reviewer and required sign-off before use.")
    doc.add_paragraph("No external notice, filing or payment has been made by exporting this dossier.")
    path = Path(output_path)
    if path.suffix.lower() != ".docx":
        raise ValueError("Output filename must end in .docx")
    path.parent.mkdir(parents=True, exist_ok=True)
    doc.save(path)
    payload = path.read_bytes()
    return {"output": str(path), "sha256": hashlib.sha256(payload).hexdigest(),
            "bytes": len(payload), "matter_id": matter_id,
            "linked_records": len(others), "format": "docx", "status": "CONTROLLED_DRAFT"}


def main():
    parser = argparse.ArgumentParser(prog="python -m themis.documents")
    parser.add_argument("--db", default="data/themis.json")
    parser.add_argument("--matter", required=True, help="Existing matter record UUID")
    parser.add_argument("--out", required=True, help="Destination .docx file")
    args = parser.parse_args()
    print(json.dumps(create_dossier(ThemisStore(args.db), args.matter, args.out), indent=2))


if __name__ == "__main__":
    main()
