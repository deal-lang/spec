# DEAL Grammar — Specification

> **Language:** DEAL — Digital Engineering Authoring Language  
> **Version:** 0.1.0-draft  
> **Status:** Phase 0 complete — ready for Stage 1 parser implementation  
> **Date:** 2026-05-18

---

## Files

| File                                | Lines   | Productions      | Purpose                                                                                |
|-------------------------------------|---------|------------------|----------------------------------------------------------------------------------------|
| `lexical.ebnf`                      | 874     | ~126 token types | Shared token definitions for both `.deal` and `.dealx` parsers                         |
| `deal.ebnf`                         | 1,954   | 102              | Definition file grammar (`.deal`) — part def, port def, requirement def, calc def, etc. |
| `dealx.ebnf`                        | 899     | 43               | Composition file grammar (`.dealx`) — `[<system>]`, `[<connect>]`, `[<satisfy>]`, etc. |
| `dealview.ebnf`                     | ~700    | 29               | View-sidecar grammar (`.dealview`) — view/tokens blocks, include/exclude membership, rules (GV-9/GV-13) |
| `DESIGN-DECISIONS.md`               | —       | —                | 68 locked design decisions — the authoritative source for what the syntax IS           |
| `maal-layer1-notation-reference.md` | —       | —                | W3C EBNF notation operators — the notation system used in all grammar files            |

## Grammar Architecture

```
lexical.ebnf (L1)              ← shared token definitions
    ↓              ↓                  ↓
deal.ebnf (L2/L3)    dealx.ebnf (L4)    dealview.ebnf (L5)
    .deal files           .dealx files       .dealview files
    definitions           compositions       view sidecars
```

The lexer uses the same token set for all file types (with mode-scoped tokens: composition tag delimiters for `.dealx`, view tokens for `.dealview` — lexical.ebnf Sections 7 and 9). The parser switches start symbol based on file extension:

- `.deal` → `DealFile` (from `deal.ebnf`)
- `.dealx` → `DealxFile` (from `dealx.ebnf`)
- `.dealview` → `DealviewFile` (from `dealview.ebnf`)

`dealx.ebnf` imports shared productions from `deal.ebnf` (HeaderBlock, Expression, AnnotationStatement, etc.); `dealview.ebnf` imports HeaderBlock and Expression. Dependencies are unidirectional — `.deal` files never reference `.dealx` or `.dealview` constructs, and `.dealview` files reference the model only (GV-9: deleting a view never affects `deal build`). Per GV-13, `dealview.ebnf` has **no element-declaring production** (the no-fabrication invariant).

## Statistics

- **173 productions** (101 in deal.ebnf + 43 in dealx.ebnf + 29 in dealview.ebnf)
- **129 token types** (keywords, operators, delimiters, literals, view-mode tokens) — includes `±` (PLUS_MINUS, SD-23)
- **82 reserved keywords** (40 global + 42 contextual) — `+4`: `calc`/`return`/`require` global, `sig` contextual (SD-21/22/23); `.dealview` mode reserves none
- **68/68 design decisions covered** (adds SD-21/22/23), plus GV-2/3/9/13 and grammar-lock decisions DV-1..DV-4 (dealview.ebnf Section 8)
- **29 parser-verified showcase files** (19 `.deal`/`.dealx` + 10 `.dealview`); **+2 grammar-spec `.deal` files** (`packages/analysis/calcs.deal`, `constraints.deal`) cover SD-21/22/23 and are pending Zig parser implementation
- **LL(1)** at 8 decision points in deal/dealx, **LL(2)** at 4 (all justified); **LL(1) everywhere** in dealview
- **No left recursion** — expression grammar uses iterative repetition

## Notation

All grammar files use **W3C EBNF** notation (XML 1.0 Fifth Edition §6). See `maal-layer1-notation-reference.md` for the complete operator reference.

Key conventions:

| Convention         | Example                   | Meaning                                               |
|--------------------|---------------------------|-------------------------------------------------------|
| `PascalCase`       | `PartDefinition`          | Public production (generates AST node)                |
| `_PascalCase`      | `_ModifierPrefix`         | Helper production (transparent, no AST node)          |
| `ALL_CAPS`         | `IDENT`, `STRING_LITERAL` | Terminal token from lexical.ebnf                      |
| `"quoted"`         | `"part"`, `"def"`         | Keyword or operator literal                           |
| `[base]` / `[ext]` | —                         | SysML v2 inherited vs DEAL extension                  |
| `[L1]`–`[L4]`      | —                         | Grammar layer (Lexical / SysML / Sugar / Composition) |

## Verification

The grammar has been verified against:

1. **Design decision coverage** — all 68 locked decisions trace to grammar productions
2. **Showcase parse coverage** — the 29 parser-verified files in `examples/showcase/` are fully parseable; the 2 SD-21/22/23 files are grammar-spec coverage pending parser implementation
3. **FIRST set disjointness** — all alternation points have disjoint FIRST sets
4. **Cross-grammar consistency** — no conflicting definitions between grammar files
5. **Tag balance** — `.dealx` grammar enforces matching open/close tags
6. **No orphan productions** — every production is reachable from a start symbol

See the Integration Verification Report for full details.

## Related Documents

| Document                        | Location                                | Purpose                       |
|---------------------------------|-----------------------------------------|-------------------------------|
| Integration Verification Report | `deal-grammar-verification-report.html` | Complete verification results |
| Parser Implementation Guide     | `deal-parser-implementation-guide.html` | Notes for Stage 1 implementer |
| Design Decisions                | `DESIGN-DECISIONS.md`                   | 68 locked syntax decisions    |
| Notation Reference              | `maal-layer1-notation-reference.md`     | W3C EBNF operator reference   |
| Showcase Project                | `examples/showcase/`                    | 19-file test corpus           |

## Next Steps

This grammar is the input to **Stage 1: "Hello World" That Sells** (~4–6 weeks):

1. Hand-written Zig lexer + recursive-descent parser
2. `deal fmt` — parser proof-of-life (parse → pretty-print → round-trip)
3. `deal build --target sysml-v2-json` — first codegen backend
4. VS Code TextMate grammar for syntax highlighting
5. Basic LSP for go-to-definition

---

*Grammar specification produced by grammar-architect workflow, Phases 1–6.*  
*68 locked decisions · 173 productions · 31 showcase files (29 parser-verified + 2 spec) · updated 2026-06-08*
