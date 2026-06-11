# calc / constraint Grammar — Locked Design

> Status: **validated, ready for grammar-architect execution** · Date: 2026-06-08
> Scope: add first-class, reusable calculation and constraint definitions to `.deal`,
> with a return-contract slot that seeds the numeric-model precision vocabulary.
> Authoritative once merged into `DESIGN-DECISIONS.md` as SD-21 / SD-22 / SD-23.

---

## 1. Motivation

DEAL evaluates expressions only *inline* today (feature values, pre/postconditions,
`@simulation:<<computes>>` bodies). There is no way to **define a named, reusable, typed
calculation or predicate**. This is the one functional gap that keeps analysis/parametric
logic out of the SSOT (see `DEAL-KerML-Coverage-Gap-Analysis.html` §4.1).

DEAL is not heading toward KerML's *declarative* model — it computes. Two complementary
paths exist:

- **In-language compute** (this design + numeric-model Lane A): dimensionally-checked
  expressions compiled to Zig, governed by an engineer-facing precision contract.
- **Farm-out** (`deal-sim`): heavy / black-box / legacy-tool physics via the JSON protocol.

This design delivers the authoring surface for in-language compute. The engine
(`deal.ebnf` §19 expression grammar, sema dimensional algebra) already exists.

---

## 2. Locked decisions (from brainstorm 2026-06-08)

| # | Decision |
|---|----------|
| D1 | **Split roles.** `calc def` = pure parameterized function (returns a value). `constraint def` = named Boolean predicate (asserts). Mirrors KerML Function vs Predicate. |
| D2 | **Return via `return expr;`** keyword (new keyword). |
| D3 | **Invariant keyword = `require`.** Multiple `require` lines = implicit **conjunction** (AND). |
| D4 | **Precision: parse now, enforce later.** Grammar + IR slot land now; sema enforcement (storage selection, error propagation, FP-determinism) is numeric-model Lane A (N-03/N-04). |
| D5 | **Return contract via `=>`**, reusing the existing `ARROW` token (precedent: `SatisfyReturnType`). The contract is a **list**. Items are a `PrecisionSpec` or a `ConstraintRef`. (`->`/`THIN_ARROW` is already taken by evidence maps + connect — not reused.) |
| D6 | **Parameters: optional direction prefix, default `in`.** `out`/`inout` allowed for full KerML fidelity (superset), discouraged by style/linter, normalized by `deal fmt`. |
| D7 | **Purity rule.** A calc with only `in` params + single `return` is *expression-valued* (composable inside expressions). Any `out` param makes it *statement-valued* (callable only in statement/`compute` position). Enforced by sema. |
| D8 | **Local bindings reuse `derived attribute name : T = expr;`** — no new `let`. |
| D9 | **`±` canonical, `+/-` ASCII alias** normalized to `±` by `deal fmt` (SD-5 pattern). Only new symbol token introduced. |
| D10 | **Evaluability scope** = KerML model-level-evaluable subset (§8.4.4.9.8): literals, unit/constant constructors, parameter/attribute refs, arithmetic/comparison/logical ops, calls to other pure calcs/constraints. No loops, I/O, or side effects — refused, belongs to `deal-sim`. The body grammar enforces most of this by providing no statement forms beyond `LocalBinding` + `ReturnStatement`. |

---

## 3. New / modified grammar productions (`deal.ebnf`)

### 3.1 calc def (new)

```ebnf
CalcDefinition ::=
    "calc" "def" IDENT ParameterList TypeAnnotation ReturnContract? CalcBody

ParameterList ::=
    "(" ( ParameterDecl ( "," ParameterDecl )* )? ")"

ParameterDecl ::=
    _DirectionPrefix? IDENT TypeAnnotation Multiplicity?     (* default direction = in (D6) *)

CalcBody ::=
    "{" ( AnnotationStatement | LocalBinding )* ReturnStatement "}"

LocalBinding ::=
    "derived"? "attribute" IDENT TypeAnnotation "=" Expression ";"   (* reuses existing forms (D8) *)

ReturnStatement ::=
    "return" Expression ";"
```

### 3.2 Return contract (new — shared by calc; available to constraint header if desired)

```ebnf
ReturnContract ::=
    "=>" ContractItem ( "," ContractItem )*

ContractItem ::=
    PrecisionSpec | ConstraintRef

ConstraintRef ::=
    QualifiedName ArgumentList?          (* references a constraint def, optionally applied *)

PrecisionSpec ::=                        (* numeric-model N-01 seed; parse now, enforce later (D4) *)
    "sig" INTEGER_LITERAL
    | "±" Tolerance

Tolerance ::=
    FunctionCallExpression               (* absolute: ± mV(1) | as-percent: ± percent(2) *)
    | NUMBER_LITERAL                     (* relative dimensionless: ± 0.001 | ± 1.0e-9 *)

NUMBER_LITERAL ::= INTEGER_LITERAL | REAL_LITERAL    (* helper alias; REAL_LITERAL already supports e-notation *)
```

`ArgumentList` is the existing call-argument production used by `FunctionCallExpression`
(reuse, do not redefine).

### 3.3 constraint def (modify existing)

Current:

```ebnf
ConstraintDefinition ::=
    "constraint" "def" IDENT StructuralRelationship? DefinitionBody
```

New:

```ebnf
ConstraintDefinition ::=
    "constraint" "def" IDENT ParameterList? StructuralRelationship? ConstraintBody

ConstraintBody ::=
    "{" ( AnnotationStatement | LocalBinding | RequireStatement )* "}"

RequireStatement ::=
    "require" ConditionExpression ";"    (* reuses existing ConditionExpression; multiple = AND (D3) *)
```

### 3.4 Wiring into existing dispatch

- Add `CalcDefinition` to the top-level definition alternation (alongside `PartDefinition`,
  `ConstraintDefinition`, etc.) and to `_MemberContent` so a definition body may own private calcs.
- `ConstraintDefinition` already dispatches at top level and in bodies — only its RHS changes.
- **No change** to `precondition`, `postcondition`, `verification`, satisfy `criteria`, or
  `compute`: because `calc`/`constraint` are callable via the existing `FunctionCallExpression`,
  those blocks can reference them with zero grammar edits. This is the redundancy-avoidance result.

---

## 4. Lexer changes (`lexical.ebnf`)

| Token | Form | Notes |
|-------|------|-------|
| `calc` | keyword | new reserved word |
| `return` | keyword | new reserved word |
| `require` | keyword | new reserved word |
| `sig` | keyword | new reserved word (precision) |
| `±` | symbol `PLUS_MINUS` | new; **`+/-` accepted as input alias, `deal fmt` → `±`** (D9) |

No `%` token and no bare-exponent token are needed: percent rides on the stdlib `percent(...)`
constructor, and relative `e-N` rides on existing `REAL_LITERAL` (requires the decimal point,
e.g. `1.0e-9`). `ARROW` (`=>`) and `THIN_ARROW` (`->`) already exist — reuse `=>`, do not touch `->`.

---

## 5. Disambiguation / FIRST-set obligations (for grammar-architect)

1. **`=>` overload.** `ARROW` is shared between `.dealx` `SatisfyReturnType ::= "=>" "{" …`
   and `.deal` `ReturnContract ::= "=>" ContractItem …`. Disjoint by FIRST after `=>`:
   `{` → satisfy return block; `sig` | `±` | `QualifiedName` (IDENT) → calc/constraint contract.
   These live in different start symbols (`.dealx` vs `.deal`) so there is no in-grammar clash,
   but verify FIRST disjointness within the `.deal` context.
2. **`calc` vs other element keywords** — unique FIRST token; `calc def` parallels `part def`.
3. **`constraint def` body** — `require` (FIRST `"require"`), `LocalBinding` (FIRST `derived`/`attribute`),
   `AnnotationStatement` (FIRST `@`) are mutually disjoint.
4. **`ParameterDecl` direction prefix** — `_DirectionPrefix?` (in/out/inout) then `IDENT`; ensure no
   clash with a parameter literally named `in`/`out` (reserved words already, so not a name).
5. **Purity rule (D7)** is a sema check, not grammar — record as a semantic obligation, not a production.

---

## 6. AST / IR notes (informative — not grammar-architect scope)

- New AST nodes: `CalcDefinition`, `ParameterDecl`, `ReturnStatement`, `ReturnContract`,
  `PrecisionSpec`, `RequireStatement`. `ConstraintDefinition` gains `params` + `requires`.
- IR: add `calc_def` and (reuse/extend) `constraint_def` `NodeKind`s; carry a
  `precision{kind, value, storage?, reproducibility?}` slot per numeric-model N-02 (values null
  until Lane A fills them). Parameters carry a `direction` enum (default `in`).
- Purity flag on the IR calc node drives the expression-position check (D7).

---

## 7. KerML mapping (superset guarantee)

| DEAL | KerML |
|------|-------|
| `calc def` (in params + `return`) | **Function** with directed parameters + `result` feature |
| `calc def` with `out` params | Function with additional directed result features |
| calc invocation in an expression | **Expression** / InvocationExpression bound to the Function |
| `return expr;` | binding of the Function `result` feature |
| `constraint def` + `require` | **Predicate** (Boolean Function); conjoined requires = its Boolean expression |
| asserting a constraint | **Invariant** |
| calc body expression subset | KerML **model-level-evaluable** subset (§8.4.4.9.8) |
| `=>` precision contract | **metadata feature** on export (preserved, not executed) — lossless round-trip |

Structure and expression trees round-trip losslessly. The precision contract and any computed
results have no native KerML field (KerML is declarative, no evaluator); they are preserved as
metadata on export and are DEAL's value-add — the superset seam.

---

## 8. Worked examples (must parse after execution)

```deal
// pure calc, composable in expressions
calc def MarginOfSafety(allowable : Stress, actual : Stress) : Real {
    return allowable / actual - 1;
}

// calc with a precision contract + named predicate, list form
calc def Drag(rho : Density, v : Speed, area : Area, cd : Real) : Force => ± percent(1), PositiveForce {
    derived attribute q : Pressure = 0.5 * rho * v * v;   // local binding
    return q * area * cd;
}

// reusable predicate
constraint def PositiveForce(f : Force) { require f >= N(0); }

// contextual invariant referencing enclosing scope
constraint def BatteryLimits { require packTemp <= degC(60) AND soc <= 1.0; }

// existing blocks call constraints for free — no grammar change to them
// precondition ready { PositiveForce(thrust) AND BatteryLimits }

// superset escape valve: multi-output calc (statement-valued, not used in expressions)
calc def SplitFlow(in total : MassFlow, out hot : MassFlow, out cold : MassFlow) {
    hot  = total * 0.6;
    cold = total * 0.4;
}
```

> Note: the multi-output `out`-param body uses assignment rather than `return`; confirm with
> grammar-architect whether `out`-param calcs use a `compute`-style assignment body or a
> distinct production. (Open micro-decision flagged for execution; default: reuse
> assignment-statement form, since `out` calcs are statement-valued by D7.)

---

## 9. Verification gates (execution exit criteria)

1. All eight worked examples in §8 parse to AST with no error (`deal parse`, exit 0).
2. `deal fmt` round-trips each losslessly; `+/-` normalizes to `±`.
3. grammar-architect collision / ambiguity / FIRST-disjointness check clean (esp. §5.1).
4. No regression: the 19-file showcase still parses; SysML v2 golden fixtures unaffected.
5. New reserved words (`calc`, `return`, `require`, `sig`) added to `keywords.zig` count + reserved list.
6. `DESIGN-DECISIONS.md` updated: **SD-21** calc def, **SD-22** constraint def + require, **SD-23**
   `=>` return contract + precision seed.

---

## 10. Open micro-decisions (resolve during execution, defaults given)

- Body form for `out`-param calcs: assignment statements (default) vs a dedicated production.
- Whether `constraint def` headers may also carry a `=>` contract (currently calc-only); default: calc-only for now.
- Exact `keywords.zig` global-vs-contextual classification for the 4 new words (likely global).
