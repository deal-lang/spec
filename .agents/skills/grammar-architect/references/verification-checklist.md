# Grammar Architect — Verification Checklist

This checklist is run at the end of each phase and during integration.
Every item must PASS before the phase gate is approved.

---

## Per-Production Checks (run for every production added)

- [ ] **P1: Design decision trace** — Production implements at least one design decision (SD-*, CS-*, LM-*, FS-*, PS-*)
- [ ] **P2: Showcase example** — At least one showcase file contains a construct parsed by this production
- [ ] **P3: Layer marker** — Production is marked with [L1], [L2], [L3], or [L4]
- [ ] **P4: FIRST tokens** — The initial token(s) that enter this production are documented
- [ ] **P5: No ambiguity** — At every alternation, FIRST sets are disjoint (or LL(2) is documented)
- [ ] **P6: Normalization target** — The DEAL IR element type (or "helper/transparent") is documented
- [ ] **P7: Notation compliance** — Only W3C EBNF operators used (no KEBNF operators)
- [ ] **P8: Naming convention** — PascalCase for non-terminals, _PascalCase for helpers, ALL_CAPS for tokens
- [ ] **P9: Production registered** — Entry added to production-registry.json

## Lexical Phase Checks

- [ ] **L1: Keyword completeness** — Every keyword from SD-1 (element keywords), SD-7 (modifiers), SD-8 (direction), and locked decisions appears in keyword table
- [ ] **L2: Operator completeness** — Every operator from SD-3, SD-4, SD-6, and composition tags from CS-2 appears in operator/delimiter table
- [ ] **L3: Literal completeness** — String (double-quote), template (backtick), integer, real, boolean from LM-3, SD-12, SD-13
- [ ] **L4: Comment completeness** — //, /* */, /** */ from SD-11
- [ ] **L5: No token collision** — No two token patterns match the same input
- [ ] **L6: No keyword shadows** — No keyword is a prefix of another that creates lexer ambiguity
- [ ] **L7: Composition delimiters** — [< , />] , [</ , >] don't collide with comparison operators
- [ ] **L8: <<operator>> delimiters** — << and >> don't collide with any other token
- [ ] **L9: Showcase token coverage** — Every token in showcase files is produced by a lexical rule

## Definition Grammar Checks

- [ ] **D1: SD-* coverage** — Every SD-* design decision has implementing production(s)
- [ ] **D2: File structure** — DealFile ::= Header Package Import* Definition* matches FS-1
- [ ] **D3: Header grammar** — All @header fields from FS-2 are parseable
- [ ] **D4: Import forms** — All 5 import forms from PS-4 are parseable
- [ ] **D5: Export/barrel** — mod.deal export syntax from PS-3 is parseable
- [ ] **D6: All element keywords** — Every keyword from SD-1 leads to a definition production
- [ ] **D7: Visibility wrappers** — public(), protected(), private() from SD-9 are parseable
- [ ] **D8: Modifiers position** — Modifiers from SD-7 precede element keywords correctly
- [ ] **D9: Direction position** — Direction from SD-8 precedes port/attribute keywords correctly
- [ ] **D10: Multiplicity** — [4], [0..1], [1..*], [*] from SD-14 parseable on attributes and parts
- [ ] **D11: Structural operators** — <<specializes>>, <<redefines>>, <<subsets>> from SD-3 tier 1
- [ ] **D12: Annotation operators** — @category:<<operator>> from SD-4 tier 2
- [ ] **D13: Verification block** — requirement def verification block from SD-20
- [ ] **D14: Use case grammar** — actor, subject, precondition, postcondition from SD-18
- [ ] **D15: Semicolons** — Required on single-line, optional on blocks per SD-10
- [ ] **D16: Unit function calls** — kg(1500), V(800) from SD-13 / PS-6
- [ ] **D17: Showcase .deal parse** — Every .deal showcase file fully parseable

## Composition Grammar Checks

- [ ] **C1: CS-* coverage** — Every CS-* design decision has implementing production(s)
- [ ] **C2: Tag syntax** — [<system>], [</system>], [<Component />] from CS-2
- [ ] **C3: Subsystem nesting** — Arbitrary depth from CS-7
- [ ] **C4: Component props** — as="name", prop={value} syntax from CS-3, CS-8
- [ ] **C5: Connect full form** — from, to, via{}, carrying{} from CS-4
- [ ] **C6: Expose** — [<expose path as="name" />] from CS-6
- [ ] **C7: Traceability block** — [<traceability>] wrapper from CS-9
- [ ] **C8: Allocate** — [<allocate>] from CS-12
- [ ] **C9: Satisfy with returns** — [<satisfy>] => {} with criteria, evidence, compute, gap from CS-10, CS-13-16
- [ ] **C10: Validate** — [<validate>] from CS-11
- [ ] **C11: Inline definitions** — .dealx can contain definitions per SD-17
- [ ] **C12: Annotations in composition** — @trace:, @behavioral:, @confidence work inside tags
- [ ] **C13: Tag balance** — Grammar enforces matching open/close tags
- [ ] **C14: Showcase .dealx parse** — Every .dealx showcase file fully parseable

## Integration Checks

- [ ] **I1: No cross-file conflicts** — No production defined differently in deal.ebnf and dealx.ebnf
- [ ] **I2: Token completeness** — Every token in lexical.ebnf used by at least one production
- [ ] **I3: No orphan productions** — Every production reachable from a start symbol
- [ ] **I4: No left recursion** — Direct or indirect (except documented Pratt parsing)
- [ ] **I5: Decision matrix** — 65/65 design decisions map to productions
- [ ] **I6: Showcase matrix** — 29/29 files fully parseable
- [ ] **I7: FIRST set disjointness** — At all major alternation points
- [ ] **I8: Error recovery points** — Synchronization tokens documented
- [ ] **I9: SysML v2 alias table** — Complete import alias mapping documented
- [ ] **I10: Keyword reservation table** — Complete list of all reserved words
- [ ] **I11: Operator precedence table** — Complete with associativity

---

## Verification Report Format

After integration, produce:

```
DEAL Grammar Verification Report
═══════════════════════════════════
Date: YYYY-MM-DD
Grammar files: lexical.ebnf, deal.ebnf, dealx.ebnf

Productions:    XX total (XX in lexical, XX in deal, XX in dealx)
Keywords:       XX reserved
Operators:      XX defined
Design decisions: 65/65 covered

Per-Production (P1-P9):    XX/XX PASS
Lexical (L1-L9):           XX/XX PASS
Definition (D1-D17):       XX/XX PASS
Composition (C1-C14):      XX/XX PASS
Integration (I1-I11):      XX/XX PASS

OVERALL: PASS / FAIL (with details of any failures)
```
