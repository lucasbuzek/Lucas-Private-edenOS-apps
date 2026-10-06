@ARGOS FETCH — HEIMDALL MASTER CONTEXT

Fetch and reconstruct the latest authoritative HEIMDALL project state from the **Homework AI RESEARCH** project and all available related conversations, project files, Library files, and prior HEIMDALL work.

## OBJECTIVE

Recover the complete current HEIMDALL architecture and requirements so this chat can continue development without requiring the user to repeat previous decisions.

Do NOT rely on an older HEIMDALL package or summary when newer decisions exist.

Use the newest explicit user decision as authoritative whenever requirements conflict.

## SEARCH SCOPE

Search for and analyze material relating to:

- HEIMDALL
- HEIMDALL Private
- HEIMDALL Desktop / Standalone
- HEIMDALL edenOS
- edenOS
- EDEN Initiative
- EDEN architecture and design principles
- Design Mantra
- calibre
- Books
- Documents
- media management
- Movies / TV
- Home Videos
- Photos
- Music / Audiobooks
- Smart Collections
- Transmission
- subtitle management
- LINGUA
- storage management
- NAS / SMB / removable storage
- Apple TV / Music / Photos integration
- DICOM
- DICOMweb
- PACS
- Orthanc
- OHIF
- FHIR / HL7 / EMR
- medical imaging
- CAD / 3D
- GIS / mapping
- scientific datasets
- projects / knowledge relationships
- offline knowledge packs
- universal file ingestion
- conversion
- indexing
- metadata
- provenance
- versioning
- Type Registry
- Capability Registry
- Provider architecture

Also analyze all relevant EDEN files rather than limiting the fetch to files explicitly named HEIMDALL.

## THREE AUTHORITATIVE BUILD FORKS

Reconstruct HEIMDALL around three distributions:

### 1. HEIMDALL PRIVATE

Personal/household deployment.

Priorities:

- fastest path to working deployment;
- initially Mac server/processor;
- responsive PWA/web interface for iPhone/iPad/Android/Windows;
- LAN authentication;
- existing Transmission integration;
- local/external/NAS storage;
- media processing;
- subtitle pipeline;
- LINGUA;
- Apple ecosystem integration;
- Books/Documents;
- integrated calibre;
- Smart Collections;
- library reconciliation;
- file management;
- experimental/new HEIMDALL capabilities may appear here first.

Private does NOT need to compromise rapid deployment merely to maintain edenOS architectural purity.

### 2. HEIMDALL DESKTOP

Native/standalone application family for:

- macOS
- Windows
- Linux

Use the shared HEIMDALL Core and provider architecture while adapting integrations to each operating system.

It should eventually provide a polished installable application rather than requiring users to administer individual backend tools.

### 3. HEIMDALL edenOS

Integrated edenOS application/service.

It must follow EDEN principles including:

- local-first;
- offline-capable where practical;
- modular;
- recoverable;
- resource-conscious;
- user data survives software replacement;
- integrations are adapters rather than owners;
- capability-driven;
- headless-capable;
- multi-user;
- suitable for field/community/deployment environments.

Major capabilities must be independently ON/OFF through Settings.

OFF means inactive/hidden, NOT destructive uninstall or deletion of user data.

## SHARED HEIMDALL CORE

Treat the following as shared platform concepts:

- persistent object identity;
- metadata;
- Type Registry;
- Capability Registry;
- storage abstraction;
- physical locations;
- multiple representations/formats;
- versions;
- provenance;
- relationships;
- projects;
- collections;
- Smart Collections;
- search;
- users/permissions;
- event engine;
- persistent job queue;
- automation/rules;
- ingestion;
- conversion;
- validation;
- backup/export;
- provider APIs.

Use specialist engines through providers rather than unnecessarily recreating mature software.

## LIBRARY TYPES

HEIMDALL is no longer limited to conventional entertainment media.

Analyze a first-class library architecture covering at least:

VIDEO

- Movies
- TV Shows
- Home Videos

AUDIO

- Music
- Audiobooks

VISUAL

- Photos
- Graphics
- Scans

READING / KNOWLEDGE

- Books
- Documents
- Papers
- Manuals
- Magazines

ENGINEERING / SCIENCE

- CAD
- 3D models
- schematics
- GIS/geospatial information
- maps
- scientific datasets

MEDICAL

- DICOM studies
- medical imaging
- reports
- clinical documents
- related healthcare information where appropriate.

## BOOKS + DOCUMENTS + CALIBRE

Books and Documents are first-class HEIMDALL library objects comparable to Movies and TV Shows.

Calibre is an integrated optional subsystem in BOTH Private and edenOS.

User experience:

Settings → Features → Books → ON/OFF

Do not require the user to administer calibre separately during normal operation.

Support:

- existing calibre libraries;
- authors;
- series;
- covers;
- metadata;
- reading;
- multiple book formats;
- conversion;
- generated representations;
- storage locations;
- Smart Collections;
- reading state;
- multiple libraries;
- backup/restore.

Different formats belong to ONE logical Book/Document where appropriate.

Example:

Book
├── EPUB
├── PDF
├── AZW3
└── KEPUB

Documents additionally require explicit VERSION management.

Example:

Document
├── v1.0
├── v1.1
└── v1.2 CURRENT
├── DOCX SOURCE
├── PDF DISTRIBUTION
└── EPUB READING COPY

Generated formats must retain provenance and must not be mistaken for new document versions.

## UNIVERSAL CONVERSION

Generalize the calibre concept into a HEIMDALL Conversion Engine.

Maintain:

SOURCE
→ DERIVED REPRESENTATION
→ GENERATOR
→ PARAMETERS
→ VALIDATION
→ PROVENANCE

Never silently replace an authoritative source with a derived representation.

For video, preserve the established Private-build requirement:

NO TRANSCODING by default.

Use compatible stream-copy/remux operations and report incompatible streams instead of silently transcoding.

## MEDICAL / DICOM — ESPECIALLY edenOS

Analyze incorporation of:

- DICOM
- DICOMweb
- PACS functionality
- Orthanc
- OHIF
- FHIR
- HL7 interoperability
- OpenMRS or equivalent integration where appropriate.

Preferred conceptual model:

MedicalLibraryProvider
├── DICOMProvider
├── DICOMwebProvider
├── DICOMViewer
├── FHIRProvider
├── HL7Provider
├── ClinicalDocumentProvider
└── EMRProvider

Investigate mature open-source components before proposing custom replacements.

DICOM hierarchy should be represented appropriately:

Patient / Research Subject
→ Study
→ Series
→ Instance

Do not claim HEIMDALL is a certified diagnostic medical device merely because it can archive/view medical imaging.

Explicitly separate:

- educational/research viewing;
- clinical interoperability;
- diagnostic/regulatory functionality.

## ENGINEERING / SCIENCE

Analyze first-class support for formats such as:

- STL
- OBJ
- 3MF
- STEP/STP
- IGES
- DXF
- SVG
- Gerber
- CSV
- JSON
- SQLite
- Parquet
- HDF5
- NetCDF
- FITS

HEIMDALL should identify and manage these objects but specialist applications/providers should perform specialist editing/analysis.

## GIS

Analyze:

- GeoTIFF
- GeoJSON
- KML
- GPX
- Shapefile
- MBTiles
- elevation data
- satellite imagery
- drone imagery.

Investigate integration with the wider EDEN/Atlas architecture rather than duplicating Atlas.

## PROJECTS + RELATIONSHIPS

Projects should become first-class logical objects.

Example:

PROJECT: gardenOS Core

Related:
├── Documents
├── Schematics
├── PCB
├── CAD
├── Firmware
├── Datasets
├── Photos
├── Videos
├── Research
└── Deployments

Physical file location must remain independent from logical project relationships.

Develop the HEIMDALL knowledge graph/relationship model rather than duplicating files into artificial folder structures.

## OFFLINE KNOWLEDGE PACKS

Especially analyze for edenOS.

A HEIMDALL Pack should be capable of bundling selected:

- books;
- documents;
- manuals;
- training;
- videos;
- maps;
- datasets;
- medical references;
- educational resources;
- repair information;
- software/resources;
- metadata/indexes.

Examples:

EDEN FIELD MEDICAL PACK

EDEN AGRICULTURE PACK

EDEN ENGINEERING / REPAIR PACK

These should remain useful with limited/no Internet connectivity.

## DEVICE INGESTION

Generalize ingestion for:

- cameras;
- phones;
- SD cards;
- USB drives;
- scanners;
- drones;
- sensor loggers;
- medical media;
- external disks.

Use:

DETECT
→ IDENTIFY CONTENT
→ PREVIEW
→ IMPORT or INDEX IN PLACE
→ VALIDATE
→ REGISTER

Never automatically destroy originals.

## SEARCH / INDEXING

Investigate universal search across:

- metadata;
- filenames;
- documents;
- books;
- OCR;
- subtitles;
- projects;
- relationships;
- datasets;
- permitted medical metadata.

AI may assist with classification, extraction, relationships, summaries, OCR cleanup and natural-language search.

AI must NOT become the authoritative datastore.

## EXISTING HEIMDALL REQUIREMENTS

Recover rather than discard previous decisions concerning:

- Transmission;
- manual magnet/.torrent intake;
- responsive/mobile UI;
- subtitle search;
- subtitle repair/synchronization;
- EN baseline subtitles;
- locality/user language profiles;
- LINGUA;
- safe remux;
- source cleanup;
- library reconciliation;
- temporary-quality replacement;
- Naming Engine;
- Apple integration;
- Smart Collections;
- tracking;
- storage identity;
- offline/removable storage;
- File Manager;
- user profiles;
- localization;
- optional feature modules;
- Home Videos;
- Photos;
- Books;
- calibre;
- provider architecture.

Do not allow the expanded scope to erase working media-center requirements.

## ANALYSIS TASK

After fetching all relevant information:

1. Reconstruct the latest authoritative HEIMDALL specification.
2. Identify contradictions, obsolete decisions and duplicated functionality.
3. Resolve conflicts using the newest explicit user decisions.
4. Analyze all relevant EDEN files for additional capabilities HEIMDALL should support.
5. Research current external technologies where freshness matters.
6. Identify mature open-source projects HEIMDALL can integrate rather than recreate.
7. Separate universal Core functionality from provider-specific functionality.
8. Determine which capabilities belong in:
   - all three forks;
   - Private only;
   - Desktop;
   - edenOS;
   - optional modules.
9. Identify security/privacy/regulatory concerns, especially for DICOM/medical data.
10. Identify further high-value capabilities not yet considered.
11. Produce an updated architecture and implementation roadmap.
12. Preserve the three-build-fork strategy.

Do not begin by asking the user to repeat information that can be recovered from Project/Library context.

Continue autonomously until the fetch, reconciliation and analysis are complete or genuine user input is required.

## DESIGN PRINCIPLE

HEIMDALL should ultimately act as:

**the library, archive, indexing, conversion, relationship, storage and information-access layer**

while specialist applications/providers handle domain-specific operations.

Maintain the established EDEN principles:

LOCAL FIRST.
USER DATA OUTLIVES SOFTWARE.
INTEGRATIONS ADAPT; THEY DO NOT OWN.
CAPABILITY, NOT HARDWARE NAME.
RECOVERY IS A PRODUCT FEATURE.
RESOURCES ARE A DESIGN BUDGET.
SIMPLE OUTSIDE; RIGOROUS INSIDE.
ONE AUTHORITATIVE IMPLEMENTATION.
DETAIL ON DEMAND.
VERIFY BEFORE DESTRUCTIVE ACTION.