# OMG ReqIF 1.2 XSD Bundle

Offline copy of the OMG Requirements Interchange Format (ReqIF) 1.2 XML Schema Definition
files used as the validation target for the DEAL ReqIF emitter.

## Source Files

| File | Source URL |
|------|-----------|
| `reqif.xsd` | `https://www.omg.org/spec/ReqIF/20110401/reqif.xsd` |
| `driver.xsd` | `http://www.omg.org/spec/ReqIF/20110402/driver.xsd` |

## Specification Reference

- **OMG Formal Document Number:** formal/2016-07-01
- **Standard:** Requirements Interchange Format (ReqIF) 1.2
- **Target Namespace:** `http://www.omg.org/spec/ReqIF/20110401/reqif.xsd`
- **Acquisition Date:** 2026-06-06

## File Descriptions

**`reqif.xsd`** (892 lines) — The primary ReqIF 1.2 schema. Declares all top-level
elements including `REQ-IF`, `CORE-CONTENT`, `REQ-IF-CONTENT`, `SPEC-OBJECTS`,
`SPEC-RELATIONS`, `SPEC-GROUPS`, and all data type definitions. This is the main
validation gate for the DEAL ReqIF emitter.

**`driver.xsd`** — The XHTML import driver referenced via `xsd:import schemaLocation`
inside `reqif.xsd`. XHTML content (e.g. `XHTML-CONTENT` within `AttributeValueXHTML`)
is typed against this schema. Bundled offline per the air-gap constraint to allow
offline schema validation without network access at build time.

## Integrity Verification

```sh
cd spec/references/omg-reqif
shasum -a 256 -c SHA256SUMS
```

## Offline Bundling Rationale

The ReqIF emitter (`Plan 04-05`) validates generated `.reqif` XML against this schema
at test time using offline validation (no network at build time — mirrors the SysML v2
JSON schema validation pattern at `spec/references/omg-sysml-v2/SysML.json`).

Without bundling `driver.xsd` alongside `reqif.xsd`, a standard XML Schema validator
would attempt to fetch `http://www.omg.org/spec/ReqIF/20110402/driver.xsd` at runtime.
This creates: (a) a network dependency at CI time, (b) a supply-chain risk (T-4-SC in
the Phase 4 threat register), and (c) fragility if the OMG URL changes.

The SHA256SUMS manifest pins both files so any byte-level tampering is detected.
Plan 04-05's `reqif_schema.rs` re-verifies the SHA256 at load time.
