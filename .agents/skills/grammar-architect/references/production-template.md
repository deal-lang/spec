# Grammar Architect — Production Documentation Template

Every production in the DEAL grammar MUST follow this template.
This is enforced by rule GA3 and GA7.

## Template

```ebnf
/**
 * [Brief description of what this production represents]
 *
 * Design decisions: [SD-X, CS-Y, ...]
 * Layer: [L1|L2|L3|L4]
 * Marker: [base|ext]
 * FIRST tokens: [token1, token2, ...]
 * Normalization: [DEAL IR element type] | [none — helper] | [transparent]
 *
 * Showcase example:
 *   [filename:line] — [snippet showing this production in use]
 *
 * Ambiguity notes:
 *   [How this production is disambiguated from alternatives]
 *
 * SysML v2 alias: [if applicable, the SysML v2 equivalent syntax]
 */
ProductionName ::=
    FirstElement
    SecondElement?
    ( AlternativeA | AlternativeB )
    RepeatedElement*
```

## Layer Markers

- **L1** — Lexical (tokens, defined in lexical.ebnf)
- **L2** — Structural definition (core element types, in deal.ebnf)
- **L3** — DEAL extensions (annotations, verification, in deal.ebnf)
- **L4** — Composition (tags, wiring, in dealx.ebnf)

## FIRST Token Documentation

At every alternation (`|`), document which token(s) determine the branch:

```ebnf
/**
 * FIRST tokens per alternative:
 *   DefinitionA → "part" (then "def" at position 2)
 *   DefinitionB → "port" (then "def" at position 2)
 *   DefinitionC → "requirement" (then "def" at position 2)
 */
Definition ::=
    PartDefinition
    | PortDefinition
    | RequirementDefinition
```

## Collision Documentation

When adding a new keyword or operator, document:

```
NEW TOKEN: "specializes"
TYPE: structural operator (within <<>> delimiters)
COLLISION CHECK:
  - Not a keyword in SysML v2 (verified against SysML-textual-bnf.kebnf)
  - Not a DEAL keyword (verified against collision-matrix.json)
  - Not a prefix of any other keyword
  - No other keyword is a prefix of this one
  - Cannot appear as an identifier because it's inside <<>> delimiters
RESULT: No collision. Safe to add.
```
