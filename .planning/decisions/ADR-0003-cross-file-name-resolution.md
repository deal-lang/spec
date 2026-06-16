---
status: "accepted"
date: 2026-06-16
decision-makers: [David (project owner)]
consulted: []
informed: []
---

# Cross-file name resolution: prefix-subtree unique binding

## Context and Problem Statement

DEAL references — type annotations, `<<specializes>>`/`<<redefines>>` targets, `@trace`
targets, and import items — must bind to declarations that frequently live in other files
and packages. Today there is **no exact cross-file resolution**: `sema`'s per-file Pass B
only verifies that a name was *imported* (an import-whitelist check, not a binding), and the
LSP's go-to-definition / find-references fall back to **suffix-matching** an unqualified name
against any indexed fully-qualified path. The showcase makes the gap concrete:
`vehicle/battery.deal` does `import interfaces.{ThermallyManaged}`, but `ThermallyManaged` is
declared in package **`interfaces.thermal`** (FQ id `interfaces.thermal.ThermallyManaged`) —
the import path is a *prefix* of the declaring package, not equal to it.

P2's hardened find-references and rename (see `DEAL-LSP-P2-Remediation-Plan.html`, Decisions 1
and 2) require binding each reference to **exactly one** declaration. Suffix-matching is
ambiguous (two `BatteryPack`s in different packages are indistinguishable) and therefore unsafe
as a foundation for rename. We must define DEAL's cross-file name-resolution semantics before
building references/rename on top.

## Decision Drivers

* Hardened find-references and rename require each reference to bind to exactly one declaration.
* Resolution must be **deterministic** and **identical** between `sema`'s diagnostics and the
  LSP's navigation — one source of truth, no drift (P2 Decision 1).
* It should preserve the showcase's existing imports where reasonable — the project treats
  folder layout as recommended-not-enforced, and authors import a package prefix (`interfaces`)
  expecting to reach declarations in its sub-packages (`interfaces.thermal`).
* Ambiguity must be **surfaced as an error**, never silently guessed.
* It must be implementable in `sema` Pass B (the resolver) and consumable verbatim by the LSP
  reverse index, so a reference's recorded `resolved_path` equals the declaring file's FQ id.

## Considered Options

* **Prefix-subtree, unique** — an import of `P` reaches declarations whose package is `P` or
  has `P` as a dotted prefix; a name binds to the unique such declaration, else it is an error.
* **Exact package-qualified** — a reference binds only to a declaration whose FQ id matches the
  import-provided qualification exactly.
* **Exact preferred, prefix fallback** — try exact first, fall back to the unique prefix-subtree
  match.
* **Suffix-match heuristic (status quo)** — bind to any decl whose FQ id ends with the name.
* **Re-export / package aggregation** — packages explicitly re-export names from sub-packages.

## Decision Outcome

Chosen option: **"Prefix-subtree, unique"**, because it binds every reference to exactly one
declaration (satisfying the rename-safety and determinism drivers) while preserving the
showcase's existing imports (a package prefix reaches its sub-package declarations), and it
turns the previously-silent same-name collision into an explicit, catchable error.

**Rule.** For an import of package `P` (named `import P.{N}` or wildcard `import P.*`), a
referenced terminal name `N` binds to the declaration `D` such that:

1. `terminal(D.id) == N` (the last `.`-segment of `D`'s fully-qualified id is `N`), **and**
2. `D`'s declaring package equals `P`, **or** begins with `P + "."` (i.e. `D` lives in `P` or a
   sub-package of `P` — `interfaces.thermal ⊆ interfaces`).

Resolution outcomes:

* **exactly one** match → bind; the reference's `resolved_path` is `D`'s actual FQ id
  (e.g. `interfaces.thermal.ThermallyManaged`).
* **zero** matches → `E2000` name-not-found (unchanged band).
* **two or more** matches → `E2001` ambiguous-name (existing code, new cross-file use).

A locally-declared name still resolves to its own declaration first; an already-fully-qualified
reference (`P.Q.N`) is treated as `P.Q` + terminal `N` under the same rule.

### Consequences

* Good, because every reference binds to a single declaration → find-references is exact and
  rename is provably safe (no bleed between same-named symbols in different packages).
* Good, because `sema` and the LSP share one resolver: the binding `sema` records (and emits in
  the index envelope's `references[]`) is the exact FQ id the LSP keys its usage index on, so
  navigation and diagnostics can never disagree.
* Good, because the showcase's existing prefix-style imports keep working unchanged.
* Bad, because it requires **real workspace-merged resolution** in `sema` Pass B: the resolver
  must see *all* workspace declarations (not just the dimension/unit entries
  `analyzeWithExternalTable` seeds today) to evaluate the prefix-subtree rule. This is a
  meaningful expansion of WS-A — a two-phase analysis (merge all declarations, then resolve each
  file against the merged table) — replacing both the per-file import-whitelist check and the
  LSP suffix-match heuristic.
* Neutral, because same-terminal-name declarations under a shared prefix that were silently
  accepted before now raise `E2001`; this may surface latent ambiguities in existing models —
  arguably a correctness improvement, but it can require authors to qualify imports further.
* Neutral, because wildcard imports (`import P.*`) use the identical prefix-subtree rule, so the
  two import forms share one resolution path.

### Confirmation

Implementation is confirmed by:

* `sema` regression fixtures: a cross-file `<<specializes>>` resolves to the declaring file's FQ
  id; a deliberately-ambiguous same-terminal-name pair under a shared prefix emits `E2001`; an
  unresolvable name emits `E2000`.
* The index envelope's `references[]` entry for the showcase `interfaces.{ThermallyManaged}`
  specialization carries `resolved_path = "interfaces.thermal.ThermallyManaged"`.
* An LSP integration test (`showcase.rs`): find-references on `ThermallyManaged` returns the
  declaration in `interfaces/thermal.deal` plus the `<<specializes>>` site in
  `vehicle/battery.deal`.
* `sema` and LSP resolution agree: a property/golden check that go-to-definition's target FQ id
  equals the authoritative binding's `resolved_path` for the same cursor.

## Pros and Cons of the Options

### Prefix-subtree, unique

`import P.{N}` binds `N` to the unique declaration under package-prefix `P` with terminal `N`.

* Good, because deterministic and unambiguous (uniqueness enforced; collisions → `E2001`).
* Good, because it preserves the showcase's prefix-style imports.
* Good, because it matches the common "import a package, reach its subtree" intuition.
* Neutral, because it requires defining "package prefix" precisely (dotted-segment prefix, not
  string prefix — `interfaces` matches `interfaces.thermal` but not `interfacesX`).
* Bad, because it needs workspace-merged resolution in `sema` (the largest cost).

### Exact package-qualified

`import P.{N}` binds only to FQ id `P.N`.

* Good, because it is the simplest, most rigorous rule and trivially unique.
* Good, because resolution needs only the declaring package, no subtree search.
* Bad, because it breaks the showcase's existing imports (would require rewriting
  `import interfaces.{…}` to `import interfaces.thermal.{…}` throughout).
* Bad, because it is the least forgiving for authors and least aligned with the
  layout-agnostic ethos.

### Exact preferred, prefix fallback

Try `P.N` exactly; else the unique prefix-subtree match.

* Good, because it is the most forgiving and accepts both exact and prefix imports.
* Neutral, because the two-tier order must be specified and tested (which wins, and when).
* Bad, because the extra tier adds resolution-order complexity and a second failure mode to
  reason about for marginal benefit over the chosen rule.

### Suffix-match heuristic (status quo)

Bind an unqualified name to any FQ id ending in `.N`.

* Good, because it requires no new resolution machinery (already how goto works).
* Bad, because it is inherently ambiguous — fatal for rename safety.
* Bad, because `sema` and the LSP resolve differently (whitelist vs suffix), so diagnostics and
  navigation can disagree. Rejected.

### Re-export / package aggregation

Packages explicitly re-export names from sub-packages.

* Good, because it makes the `interfaces` → `interfaces.thermal` reach explicit and auditable.
* Bad, because it is a new language feature (export lists) — heavy, and out of scope for P2.
  Rejected (may revisit independently).

## More Information

### Implementation impact (WS-A)

This decision **expands WS-A** beyond per-file binding capture. The resolver (`resolveName` in
`sema.zig`, introduced in P2 slice 2) generalizes to: local declaration → its id; else the
prefix-subtree-unique match over a **workspace-merged declaration table**; else `E2000` /
`E2001`. That merged table requires a two-phase analysis — collect every file's declarations
(Pass A across the workspace), then run Pass B per file resolving against the union. The LSP's
`eager_parse` (today independent per-file parses) and the CLI workspace check must drive this
merge. The reference binding's `resolved_path` then equals the declaring file's actual FQ id,
which is exactly the key the LSP reverse index (`Index::usages`) uses — making find-references
and rename correct and consistent with go-to-definition.

Slices 1 and 2 already landed (the `Binding` type, index `references[]` emission/ingest, the
`textDocument/references` handler, and a first `resolveName`); they are correct for same-file
references today and become correct for cross-file references once the workspace-merged
resolution from this ADR is implemented.

### Related Decisions

* `DEAL-LSP-P2-Remediation-Plan.html` — WS-A (authoritative bindings) and Decisions 1 & 2.
* `ADR-0001` / `ADR-0002` — IR v0.1 / v0.2 (binding records ride in the index/IR envelope).

### Requirements Traceability

* P2 find-references / rename: requires exactly-one-declaration binding — addressed by the
  uniqueness clause and `E2001` on ambiguity.
