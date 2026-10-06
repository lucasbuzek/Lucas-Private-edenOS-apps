EDEN / edenOS CORE — CONSOLIDATED DESIGN & REFERENCE BACKUP
Version: 0.1
Date: 2026-09-22
Owner: Lucas Buzek
EDEN: Engineering, Development, Exploration & Nature

PURPOSE
This package consolidates the recovered gardenOS → edenOS Core → machine ecosystem architecture, Nandi and dedicated-machine lineage rules, current hardware requirements, and an external open-source/product reference register. It is designed as both a working architecture package and a recovery/backup package.

CANONICAL LINEAGE
gardenOS Core is the proven engineering ancestor/test bed.
Generic, reusable capabilities are progressively extracted/generalized into edenOS Core.
edenOS Core is the common architecture/runtime.
gardenOS remains the agriculture/environment domain application.
NANDI remains the tiny universal-helper machine lineage across domains.
Dedicated machines (e.g. Mechanical Mule) retain their own lineages while sharing edenOS Core architecture.

NON-NEGOTIABLE RULE
IMPLEMENT / INTEGRATE EXISTING CAPABILITY BEFORE RECREATING IT.
Before adding to edenOS Core, check gardenOS and the external reference register first.

BACKUP CONTENTS
01_CANONICAL_DESIGN — authoritative consolidated architecture.
02_gardenOS_LINEAGE — what is inherited/extracted from gardenOS.
03_MACHINE_ARCHITECTURE — machine Core, hardware, safety, modules and interfaces.
04_NANDI — Nandi role and prototype progression.
05_EXTERNAL_REFERENCES — organized research references by subsystem/domain.
06_SOURCE_BACKUP — copies of available EDEN source/reference files plus reproducible external-source manifests.
07_LINKS — master URL register.
08_LICENSE_PROVENANCE — licensing/provenance controls before reuse.
09_RECOVERY — instructions to rebuild the reference library.
10_CHANGELOG — package history.

IMPORTANT
External projects are references/integration candidates, not automatically EDEN dependencies. Do not copy code, PCB, CAD, media or documentation into EDEN production code until its exact license and provenance have been reviewed.
