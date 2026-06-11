# DEAL IR v0 Reference

**Normative schema:** [`spec/ir/v0/schema.json`](./schema.json) (JSON Schema draft-2020-12)
**ADR:** [`.planning/decisions/ADR-deal-ir-v0.md`](../../.planning/decisions/ADR-deal-ir-v0.md)
**Status:** PROPOSED (becomes LOCKED after IR-LOCK checkpoint review, D-37)

---

## Overview

IR v0 is the **kernel data model** that DEAL phases 2–6 build against. It is lowered from the parsed AST plus the semantic analyzer's symbol table. Phases 3 (LSP), 4 (ReqIF emitter), 5 (simulation bindings), and 6 (importers) all consume the IR — none of them re-parse source files or re-resolve names.

Transport across the FFI boundary is **JSON via `deal_ir_json()`** — the 7th C ABI export, following the established length-prefixed UTF-8 pattern (D-11). The Rust CLI deserializes via serde_json into typed structs; Plan 02-04 is the first consumer.

The IR is **comment-free** (D-25). Comments and trivia live on the AST only. `deal fmt` walks the AST; SysML v2 emitter, ReqIF emitter, and sim bindings walk the IR.

---

## ID Strategy (D-23)

Every IR node has a unique **fully-qualified path string** as its ID:

```
<package-segment>.<package-segment>...<element-name>.<member-name>
```

**Examples:**
- `vehicle.battery.BatteryCell` — a part definition in package `vehicle.battery`
- `vehicle.battery.BatteryCell.nominalVoltage` — an attribute member
- `vehicle.battery.BatteryPack.hvOut` — a port usage
- `requirements.system.SafetyRequirement` — a requirement definition

**Separator:** `.` (period). The current 19-file showcase has no identifiers containing literal `.`, but consumers should be aware that a future escape convention may be introduced if needed.

**Translation to SysML v2:**
- `.` separator → `::` for `qualifiedName`
- `@id` / `elementId` in SysML JSON: synthesized UUID v5 with namespace OID
  `NAMESPACE_OID = "6ba7b812-9dad-11d1-80b4-00c04fd430c8"` and name = the
  fully-qualified path string (per RESEARCH §Pitfall 5). This synthesis is
  deterministic — the same qualified path always maps to the same UUID.

**Uniqueness guarantee:** sema's name-resolution check (E2000 band) ensures no two
declarations share the same fully-qualified path within a workspace. The lowering pass
can rely on this invariant — no collision checking in the lowering pass.

---

## Span Carry-Over from AST (D-15 + RESEARCH §Pattern S-10)

Every IR node carries the AST span verbatim:

```json
"span": [657, 1562]
```

Spans are **u32 byte offsets** into the duped source buffer — `span[0]` is the first byte of the declaration keyword, `span[1]` is one past the last byte of the closing `}` or semicolon.

Spans are used for:
- Diagnostic attachment points — when the SysML emitter or sim bindings emit an error against an IR node, the span enables source-located diagnostics
- LSP hover and go-to-definition (Phase 3)
- Round-trip test verification — every IR node span must correspond to a valid source location in the original file

**Important:** span byte offsets are relative to the per-file source buffer. The `source_file` field identifies which file.

---

## Relationship Graph Contract (D-24, RESEARCH §Pattern 6)

Edges are stored in the top-level `"edges"` **adjacency list**, NOT inline on nodes.
This keeps the serialized form tree-shaped (JSON objects) while the semantic model is graph-shaped.

```json
{
  "edges": [
    {"dst": "interfaces.ThermallyManaged", "kind": "specializes", "src": "vehicle.battery.BatteryPack"},
    {"dst": "requirements.system.R_BatteryRange", "kind": "satisfies",  "src": "vehicle.battery.BatteryPack"},
    {"dst": "vehicle.battery.BatteryPack.cells",  "kind": "contains",   "src": "vehicle.battery.BatteryPack"}
  ],
  ...
}
```

**Edge kinds:**

| Kind | Meaning | Typical source |
|------|---------|----------------|
| `specializes` | `<<specializes>>` declaration | ElementDef with `specializes` clause |
| `redefines` | `<<redefines>>` redefinition | ElementDef with `redefines` clause |
| `subsets` | `<<subsets>>` subset | ElementDef with `subsets` clause |
| `satisfies` | `@trace:<<satisfies>>` link | Annotation on part/block |
| `allocated_to` | `allocate` statement | .dealx `allocate` tag |
| `derives_from` | `<<derives>>` derivation | ElementDef with `derives` clause |
| `imports` | `import` statement | ImportDecl at file level |
| `traces` | Generic `@trace` annotation | Annotation without `<<satisfies>>` |
| `contains` | Parent → child ownership | Lowering: members within defs |
| `connects_via` | Composition wiring | .dealx `connect` block |
| `carries` | Flow content | .dealx `carrying` specification |

**Indexed for O(1) traversal:** The lowering pass builds two adjacency indexes:
- `incoming_index`: `id → []EdgeRef` — for `references(id)` queries
- `children_index`: `id → []const u8` — for `children(id)` queries, using `contains` edges only

---

## Metadata Envelope Shape

### agent_metadata (optional)

Carries `@confidence`, `@rationale`, `@assumes`, `@concerns` annotation values lowered from the AST into a **typed envelope**:

```json
"agent_metadata": {
  "assumes": ["Cell supplier delivers to IEC 62660-1 qualification"],
  "confidence": 0.95,
  "concerns": [],
  "rationale": "NMC 811 selected over LFP per trade study TS-2026-004"
}
```

**Rules:**
- All four fields are optional; absent = not set in source
- `assumes` and `concerns` are arrays (preserves source annotation order)
- `confidence` is a float (f64); typically 0.0–1.0 by convention but unconstrained in schema
- `rationale` is a string (the literal value after `@rationale:`)
- Keys alphabetical: `assumes, concerns, confidence, rationale` — null/absent fields omitted (D-18)

**Phase usage:**
- Phase 2 SysML emitter: ignores (no SysML v2 mapping for these fields in Phase 2)
- Phase 3 LSP: surfaces in hover tooltips
- Phase 5 sim bindings: reads `confidence` as the weighting input to simulation evidence scoring

### simulation_bindings (optional)

Carries `@simulation:<<computes>>` and `@simulation:<<validates against>>` annotation values:

```json
"simulation_bindings": [
  {
    "equation": "T_cell > 150°C triggers thermal event",
    "fidelity": "CFD",
    "operator": "computes",
    "target": "thermalRunaway",
    "tool": "ANSYS Fluent"
  }
]
```

**Fields (alphabetical — optional fields omitted when absent):**
- `entry` — Python/MATLAB function entry point name
- `equation` — equation string from annotation body
- `fidelity` — fidelity descriptor (`"CFD"`, `"lumped-parameter"`, etc.)
- `operator` — `"computes"` or `"validates_against"` (note: `<<validates against>>` maps to `validates_against` — spaces become underscores)
- `target` — the simulated quantity name (always present)
- `tool` — tool name from annotation body

**Phase usage:**
- Phase 2 SysML emitter: **ignores** this field entirely
- Phase 5 sim bindings: reads to wire up simulation execution

---

## Diagnostic Attachment Points

Every IR node carries `span` (byte offsets) and `source_file` (workspace-relative path). Diagnostics emitted by downstream consumers (SysML emitter, sim bindings, LSP) attach to these coordinates.

**Contract:** `source_file` is always workspace-relative (never absolute). This is enforced by sema (T-02-11 path traversal mitigation) and carried verbatim into IR nodes by the lowering pass.

---

## Backend Traversal API (D-26 LOCKED)

The Zig `ir.Document` type exposes five methods as the LOCKED public contract for in-process consumers (tests, codegen, future LSP integration):

```zig
pub const Document = struct {
    elements: std.StringHashMap(*IrNode),
    edges: []Edge,
    incoming_index: std.StringHashMap([]EdgeRef),
    children_index: std.StringHashMap([]const u8),

    /// Pre-order + post-order visitor traversal over all elements.
    /// visitor must expose: fn preOrder(*IrNode) void + fn postOrder(*IrNode) void.
    /// Duck-typed via anytype — no interface allocation.
    pub fn walk(self: *const Document, visitor: anytype) !void;

    /// Resolve a fully-qualified path ID to its IrNode. O(1) hash lookup.
    pub fn find(self: *const Document, id: []const u8) ?*IrNode;

    /// All incoming edges to the node with the given ID. O(1) index lookup.
    pub fn references(self: *const Document, id: []const u8) []const EdgeRef;

    /// Direct children of the node with the given ID (via 'contains' edges). O(1).
    pub fn children(self: *const Document, id: []const u8) []const []const u8;

    /// Parent of the node with the given ID, inferred from the qualified path prefix.
    /// Returns null for top-level package nodes.
    pub fn parent(self: *const Document, id: []const u8) ?[]const u8;
};
```

**Not in v0:** Query DSL (MQL is deferred per PROJECT.md ADR). Ad-hoc queries are coded as visitors passed to `walk`.

---

## JSON Envelope (D-22 + D-18)

```json
{
  "edges":      [...],
  "elements":   {...},
  "ir_version": "v0",
  "v":          1
}
```

- **Top-level keys alphabetical:** `edges, elements, ir_version, v`
- **Per-element keys alphabetical:** `kind, payload, source_file, span`
- **Per-edge keys alphabetical:** `dst, kind, src`
- **Payload keys alphabetical** per kind; `agent_metadata` before `modifiers`, `modifiers` before `name`, etc.
- **Encoding:** UTF-8, no BOM, no NUL terminator (length-prefixed across FFI per D-11)
- **No `std.json.Stringify`:** hand-rolled emission in `src/json.zig emitIrJson` (RESEARCH §Pitfall 1)

---

## Example: Minimal IR Document

The following is a representative IR snippet for a fragment of `tests/showcase/packages/vehicle/battery.deal`:

```json
{
  "edges": [
    {
      "dst": "interfaces.electrical.HVDCPort",
      "kind": "specializes",
      "src": "vehicle.battery.BatteryPack.hvOut"
    },
    {
      "dst": "vehicle.battery.BatteryPack",
      "kind": "contains",
      "src": "vehicle.battery.BatteryPack.hvOut"
    },
    {
      "dst": "vehicle.battery.BatteryCell",
      "kind": "contains",
      "src": "vehicle.battery.BatteryPack"
    }
  ],
  "elements": {
    "vehicle.battery": {
      "kind": "package",
      "payload": {
        "name": "battery"
      },
      "source_file": "packages/vehicle/battery.deal",
      "span": [0, 4096]
    },
    "vehicle.battery.BatteryCell": {
      "kind": "part_def",
      "payload": {
        "agent_metadata": {
          "assumes": ["Cell supplier delivers to IEC 62660-1 qualification"],
          "confidence": 0.95,
          "rationale": "NMC 811 selected over LFP per trade study TS-2026-004"
        },
        "name": "BatteryCell",
        "simulation_bindings": [
          {
            "equation": "T_cell > 150°C triggers thermal event",
            "fidelity": "CFD",
            "operator": "computes",
            "target": "thermalRunaway",
            "tool": "ANSYS Fluent"
          }
        ]
      },
      "source_file": "packages/vehicle/battery.deal",
      "span": [297, 897]
    },
    "vehicle.battery.BatteryPack": {
      "kind": "part_def",
      "payload": {
        "agent_metadata": {
          "assumes": ["Structural enclosure passes FMVSS 305 per supplier commitment"],
          "confidence": 0.82,
          "concerns": ["Pack-level crash safety analysis incomplete"],
          "rationale": "800V architecture selected for charging speed per ADR-012"
        },
        "name": "BatteryPack"
      },
      "source_file": "packages/vehicle/battery.deal",
      "span": [1024, 2048]
    },
    "vehicle.battery.BatteryPack.hvOut": {
      "kind": "port_usage",
      "payload": {
        "direction": "out",
        "name": "hvOut",
        "type_ref": "interfaces.electrical.HVDCPort"
      },
      "source_file": "packages/vehicle/battery.deal",
      "span": [1105, 1140]
    }
  },
  "ir_version": "v0",
  "v": 1
}
```

---

## Stability

v0 is the **public contract surface**. All of Phases 3–6 build against this shape.

**Additive changes are allowed within v0** as long as:
1. `spec/ir/v0/schema.json` is updated with the new optional field
2. Golden fixture files under `tests/golden/` are regenerated
3. `determinism.lower_twice` still passes

**Breaking changes** (renaming a NodeKind, removing a required field, changing edge direction semantics) require:
1. A new ADR referencing this one
2. A `ir_version` bump from `"v0"` to `"v1"` in the JSON envelope
3. Migration guide for all existing consumers

**D-37 IR-LOCK checkpoint:** After Plan 02-03 ships, the orchestrator records a human review outcome in `02-IR-LOCK.md`. Upon approval, this ADR's Status field flips from PROPOSED to LOCKED. Plans 02-04 and 02-05 may run in parallel only after recorded approval.
