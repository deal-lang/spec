---
status: "accepted"
date: 2026-06-17
decision-makers: [David (project owner)]
consulted: []
informed: []
supersedes: ADR-0003
---

# Module resolution & import scoping: an import-graph model

## Context and Problem Statement

[ADR-0003](ADR-0003-cross-file-name-resolution.md) chose **flat workspace-merged resolution**:
every declaration in the workspace (plus stdlib) is merged into one table, and each file is
resolved against the union. In practice this made `import` statements **semantically thin**:

* A **bare** reference (`ThermallyManaged`) resolves only via an import — but a **qualified**
  reference (`interfaces.thermal.ThermallyManaged`) resolves against the entire merged table with
  **no import required and no diagnostic**. A model written with qualified paths could delete every
  `import` line and still compile.
* The workspace is parsed **eagerly and in its entirety**; the recorded `imports_graph` drives
  nothing; the `W0500` unused-import warning is defined but never emitted.
* There is **no encapsulation**: nothing can be internal to a package; every declaration is
  globally reachable by path. Analysis cost is **O(workspace)** for every check and every LSP
  start.

ADR-0003 resulted from a **miscommunication**. The original intent behind it was *not* "merge
everything" — it was to remove the previously **hard-coded layout** (`*.deal` had to live under
`packages/`, `*.dealx` under `model/`) and make file placement **recommended-not-enforced**, the
way TypeScript resolves `.ts`/`.tsx` from a configured project regardless of folder layout. The
correct model is **module-graph resolution**: a file sees only what it imports; `deal.toml`
defines where modules live and provides aliases so imports are logical names, not relative/absolute
paths; and the toolchain loads only the **import-reachable closure** rooted at compositions.

This ADR supersedes ADR-0003 and defines DEAL's resolution and import-scoping semantics.

## Decision Drivers

* **Encapsulation.** Imports must be the *enforced* channel of cross-module visibility, so models
  can have internal detail and so the import list is a trustworthy dependency record.
* **Reuse & sharability of `.deal` definitions.** The model must make curated, re-exportable
  package surfaces (barrel/facade packages) easy, so definitions compose without exposing internals.
* **Scalability.** Loading and analysis must be **O(import-reachable)**, not O(workspace) — only
  parse what is reached from the entry points being worked on.
* **Layout-agnostic, config-driven.** `deal.toml` (not hard-coded directories) defines workspace
  roots and import aliases; the recommended `packages/` + `model/` layout is a convention, not a
  contract.
* **Determinism & single source of truth.** `sema` diagnostics and LSP navigation must resolve
  identically (the ADR-0003 driver we keep).
* **Pre-release.** No backward-compatibility obligation; we choose the correct end state and update
  the example models to match.

## Considered Options

* **Import-graph module model** — a file sees primitives + its own declarations + what it imports
  (+ re-exports it pulls in); any reference to a name not visible is an error; loading follows the
  import closure from entry points.
* **Flat workspace-merge (ADR-0003, status quo)** — merge all declarations; imports gate bare
  names only; load the whole workspace.
* **Hybrid: enforce on bare, allow qualified** — keep qualified-path escape hatch, enforce only
  bare names (essentially the status quo, formalized).

## Decision Outcome

Chosen option: **the import-graph module model**, because it delivers encapsulation, makes imports
load-bearing and lint-able, bounds analysis cost to the reachable set, and matches the
`.deal`/`.dealx` design (definitions vs compositions). It supersedes ADR-0003's flat merge.

The model is defined by seven rules.

### R1 — Workspaces are defined by `deal.toml`, not by directory layout

`deal.toml` declares the workspace's **package roots** and **aliases**. File placement is
recommended (`packages/` for `.deal`, `model/` for `.dealx`) but **not enforced** — a `.deal`/
`.dealx` file is discovered by configuration + extension, never by directory name. A package
namespace (`spacecraft`, `deal.std.units`) is bound to a location by `deal.toml`, so imports use
**logical names**, never relative/absolute filesystem paths.

```toml
# deal.toml (shape — finalized in the implementation plan)
[workspace]
roots = ["packages", "model"]        # where to discover modules (recommended defaults)

[aliases]
spacecraft = "packages/spacecraft"   # import namespace → location
interfaces = "packages/interfaces"
```

### R2 — Visibility is import-scoped; the prelude is primitives only

Within any module, the resolvable names are exactly:

1. the **prelude** — built-in primitive types only (`Real`, `Integer`, `Boolean`, `String`, and
   the language's intrinsic types). *Nothing else is implicit* — units, dimensions, every package,
   and the entire stdlib must be imported;
2. the module's **own declarations**; and
3. names brought in by its **imports** (named items, or a package's public surface via wildcard),
   including names a package's barrel `export`s (R6).

A reference — **bare or qualified** — to any name not in that set is **`E2000` name-not-found**.
Qualified paths are no longer a global escape hatch. (This is the central reversal of ADR-0003.)

### R3 — Resolution & loading order (entry-point / closure driven)

1. Read `deal.toml`; build the alias/root map.
2. Determine **entry points**: for `deal check`, the files/compositions requested (default: all
   `.dealx`); for the LSP, the open file plus the workspace's `.dealx` compositions.
3. Parse each entry point, read its `import` lines, resolve each to module(s) via the alias map,
   load those modules, and **recurse** — building the analysis set from the **import closure**.
4. Files that nothing imports are **not parsed**. Dependencies (stdlib, installed packages) are
   ordinary modules reached through imports, so only the **imported** stdlib modules are loaded.

### R4 — Import granularity: named binds items, wildcard binds the package surface

* `import deal.std.units.{km, m, mm};` binds **only** `km`, `m`, `mm`.
* `import spacecraft.*;` binds the **public surface of package `spacecraft`** — its own public
  declarations plus everything it `export`s (R6 — its barrel). It does **not** auto-descend into
  sub-packages: `spacecraft.eps` members are reachable only if `spacecraft` re-exports them
  (a barrel) or by importing `spacecraft.eps` directly. This keeps packages encapsulating and
  makes the public surface explicit.

### R5 — Import placement differs by file kind

* **`.deal` (definitions):** `import` may appear **anywhere** — at file top, inside a `package`
  block, or nested in a scope — binding into the **enclosing scope**. This maximizes reuse and
  sharability: a definition file can pull a dependency into exactly the scope that needs it.
* **`.dealx` (compositions):** `import` may appear **only at the top of the file**, and is
  **file-scoped**. Compositions are application roots; their imports are a flat, top-level manifest.

### R6 — `import` is always local; `export` re-exports (barrels)

> **Amended 2026-06-18 (grounded in TypeScript / Next.js).** The original R6 used D-style
> `public import`. DEAL already has a separate `export` construct that is exactly TypeScript's
> `export … from`, and the cubesat barrels already use it. Rather than add a redundant second
> re-export mechanism, this ADR adopts `export` as the **sole** re-export channel and drops
> `public`/`private import`. TypeScript keeps `import` (consume → local) and `export … from`
> (re-export → no local binding) orthogonal; DEAL follows suit.

* A plain **`import`** is **always local** — the imported names are visible **only inside the
  importing module**, a private implementation detail. There is **no visibility modifier** on
  `import`.
* An **`export`** *re-exports* names from a sub-module as part of the importing package's **own
  public surface**: any module that imports this package (or wildcard-imports it) also sees them.
  This is TypeScript's `export … from` / the barrel pattern, and it is how **barrel/facade
  packages** are built:

```deal
// packages/spacecraft/index.deal — curated public surface for the package
package spacecraft;
export eps.{BatteryPack, SolarArray};
export adcs.{ReactionWheel};
```
```dealx
// model/halcyon.dealx
import spacecraft.*;   // sees BatteryPack, SolarArray, ReactionWheel via the barrel
```

Re-export is transitive through `export` chains; a plain `import` never propagates. Following
Next.js's barrel guidance (wildcard re-export defeats tree-shaking), `export` is **named-only** —
there is no wildcard `export`.

### R7 — Enforcement is strict from the start

Un-imported references are errors (`E2000`) immediately — no staged migration, no legacy flag. The
repository's example models (`cubesat`, `showcase`) are **updated to be import-clean** as part of
the implementing work. `W0500` unused-import becomes meaningful and **is emitted**.

### Consequences

* Good, because imports become the enforced, trustworthy, lint-able boundary of visibility;
  packages encapsulate; barrel re-export makes curated public surfaces easy (the reuse driver).
* Good, because loading is O(import-reachable): the LSP parses the open file's closure, not the
  repo; the dependency/stdlib story becomes "only the imported modules are loaded."
* Good, because it removes the flat-merge pressure that forces 50+ sources through the analyzer at
  once (the volume that surfaced the stdlib SIGSEGV — see the dependency-resolution assessment).
* Good, because `deal.toml` aliasing removes relative/absolute path imports and decouples logical
  module names from disk layout.
* Bad, because it is a **breaking semantic change**: models that relied on qualified-path
  resolution without imports stop compiling until imports are added. Mitigated by pre-release
  status, the example-update work (R7), and an LSP "add import" quick-fix.
* Bad, because it is a **substantial implementation surface**: parser (import placement + nested
  imports), sema (scoped visibility, `export` re-export propagation, closure loading,
  `E2000` on un-imported, `W0500`), the `deal.toml` workspace/alias model, the CLI check driver,
  and the LSP loader — sequenced in the roadmap that follows this ADR.
* Neutral, because the `imports_graph` already recorded in Pass A becomes the live driver of
  loading rather than inert metadata.

### Confirmation

Implementation is confirmed by:

* **Scoping:** a qualified reference to a non-imported symbol emits `E2000`; the same reference with
  the import present resolves. A barrel `export` makes a name visible to a downstream importer; a
  plain `import` does not (the downstream importer gets `E2000`).
* **Closure loading:** opening a composition parses exactly its transitive import set — a file that
  nothing imports is not parsed; a property check asserts `parsed-set == import-closure`.
* **Granularity:** `p.{A}` makes `A` visible and `B` not; `p.*` makes the package's public surface
  visible but not an un-re-exported sub-package member.
* **Placement:** an `import` nested in a `.deal` package block resolves within that scope; the same
  nested import in a `.dealx` file is a syntax/scope error (top-of-file only).
* **Prelude:** `Real`/`Integer`/… resolve with no import; `Voltage`/`kg` do not until imported.
* **Unused import:** `W0500` fires for an import with no covered reference.
* **Examples:** `cubesat` and `showcase` compile clean under strict enforcement after the
  import-clean update.

## Pros and Cons of the Options

### Import-graph module model (chosen)

* Good — encapsulation, trustworthy imports, O(reachable) loading, matches `.deal`/`.dealx`.
* Good — barrel re-export (`export`) directly serves the reuse/sharability driver.
* Bad — breaking change + large implementation surface (accepted; pre-release).

### Flat workspace-merge (ADR-0003)

* Good — already implemented; simplest resolver.
* Bad — no encapsulation; imports decorative for qualified refs; O(workspace); the model this ADR
  supersedes. Rejected.

### Hybrid: enforce bare, allow qualified

* Good — smaller change than full enforcement.
* Bad — keeps the qualified escape hatch, so encapsulation and import-trust are never achieved; the
  worst of both. Rejected.

## More Information

### Package model & declaration visibility

A package is declared with `package foo.bar;`; multiple files may contribute to one package. A
package's **public surface** is its top-level declarations (public by default within the model,
importable by other modules) plus its `export` re-exports. (A future `private`/`internal`
modifier on a top-level declaration to make it package-internal is a possible extension, noted but
not decided here.) The existing in-definition visibility groups (`public(...)`, `protected(...)`)
are a separate, orthogonal feature (member visibility *within* a def) and are unaffected.

### Interaction with the dependency-resolution work

The borrowed-pointer **use-after-free** in `analyzeWithExternalTable` (see
`DEAL-LSP-Dependency-Resolution-Assessment.html`) is a **correctness bug fixed independently and
first** — any external declaration fed to analysis must be owned by the analysis arena, regardless
of resolution model. This ADR changes *how much* external source is fed and *when* (only the
import-reachable closure, lazily), and reframes "index the whole workspace + all deps merged" as
"load the import closure." The dependency/workspace loader is therefore built **on this ADR**, not
on the flat merge — which is why this decision must precede that loader work.

### Related decisions

* Supersedes `ADR-0003` (cross-file name resolution / flat merge).
* `DEAL-LSP-Dependency-Resolution-Assessment.html` — the UAF fix and dependency materialization.
* `DEAL-Module-Resolution-Scoping-Assessment.html` — the analysis motivating this ADR.
* `ADR-0001` / `ADR-0002` — IR v0.1 / v0.2 (the `imports_graph` rides in the index/IR envelope).

### Requirements traceability

* Encapsulation + trustworthy imports → R2 (import-scoped visibility, `E2000` on un-imported), R7
  (strict + `W0500`).
* Reuse/sharability → R5 (anywhere-in-`.deal` placement), R6 (`export` re-export / barrels).
* Scalability → R3 (closure-driven loading), R4 (granular binding).
* Layout-agnostic → R1 (`deal.toml` roots + aliases).
