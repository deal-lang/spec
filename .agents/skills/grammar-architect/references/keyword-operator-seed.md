# Grammar Architect — Keyword and Operator Seed List

Extracted from the 65 locked design decisions. This is the starting point
for the collision matrix. The lexical phase (Phase 2) validates and extends this.

---

## Element Keywords (SD-1)

Definition form: `keyword "def"` — Usage form: `keyword`

| Keyword | Definition | Usage | Category |
|---------|-----------|-------|----------|
| part | part def | part | structural |
| port | port def | port | structural |
| action | action def | action | behavioral |
| state | state def | state | behavioral |
| attribute | attribute def | attribute | structural |
| item | item def | item | structural |
| interface | interface def | interface | structural |
| connection | connection def | connection | physical |
| flow | flow def | flow | logical |
| allocation | allocation def | allocation | trace |
| requirement | requirement def | requirement | requirement |
| constraint | constraint def | constraint | constraint |
| need | need def | need | requirement |
| use case | use case def | use case | behavioral |

**Note:** `use case` is a two-word keyword (like SysML v2). The lexer
must recognize `use` followed by `case` as a compound keyword token.

## Modifier Keywords (SD-7)

| Keyword | Metamodel Property | Position |
|---------|-------------------|----------|
| abstract | isAbstract | before element keyword |
| derived | isDerived | before attribute/part keyword |
| readonly | isReadOnly | before attribute keyword |
| ordered | isOrdered | before part/attribute keyword |
| nonunique | isNonUnique | before part/attribute keyword |
| individual | — | before part keyword |
| variation | isVariation | before element keyword |
| portion | isPortion | before part keyword |
| end | isEnd | before part keyword |
| ref | isReference | before part keyword |

## Direction Keywords (SD-8)

| Keyword | Position |
|---------|----------|
| in | before port/attribute keyword |
| out | before port/attribute keyword |
| inout | before port/attribute keyword |

## Visibility Keywords (SD-9)

| Keyword | Usage |
|---------|-------|
| public | public ( ... ) scope wrapper |
| protected | protected ( ... ) scope wrapper |
| private | private ( ... ) scope wrapper |

## Import/Export Keywords (PS-3, PS-4)

| Keyword | Usage |
|---------|-------|
| package | package declaration |
| import | import statement |
| export | barrel export in mod.deal |
| as | alias in import/expose |
| from | (reserved for future use case grammar) |

## Other Keywords

| Keyword | Source | Usage |
|---------|--------|-------|
| def | SD-1 | follows element keyword in definitions |
| actor | SD-18 | use case actor declaration |
| subject | SD-18 | use case subject declaration |
| precondition | SD-18 | use case precondition block |
| postcondition | SD-18 | use case postcondition block |
| verification | SD-20 | requirement verification block |
| accepts | SD-20 | verification accepted methods |
| rejects | SD-20 | verification rejected methods |
| threshold | SD-20 | verification threshold attribute |
| operator | SD-20 | verification comparison operator |
| conditions | SD-20 | verification environmental conditions |
| true | — | boolean literal |
| false | — | boolean literal |
| AND | — | logical operator in criteria expressions |
| OR | — | logical operator in criteria expressions |
| NOT | — | logical operator in criteria expressions |

## Structural Operators — Tier 1 (SD-3, SD-4)

Appear at declaration level without @category: prefix.

| DEAL Form | SysML v2 Alias | Meaning |
|-----------|---------------|---------|
| <<specializes>> | :> | specialization |
| <<redefines>> | :>> | redefinition |
| <<subsets>> | :> (feature context) | subsetting |
| <<references>> | ::> | reference subsetting |
| <<conjugates>> | ~ | conjugation |

## Annotation Operators — Tier 2 (SD-4, SD-6)

Appear as @category:<<operator>> in element bodies.

| Category | Operators |
|----------|-----------|
| @trace: | <<satisfies>>, <<partially satisfies>>, <<derives from>>, <<verified by>>, <<allocated to>>, <<validates>> |
| @connection: | <<connects>> |
| @flow: | <<flows to>> |
| @behavioral: | <<performs>>, <<exhibits>> |
| @simulation: | <<computes>>, <<validates against>> |
| @requirement: | (TBD) |
| @state: | (TBD) |
| @temporal: | (TBD) |

## Composition Tags (CS-2)

| Tag | Form | Grammar |
|-----|------|---------|
| system | [<system Name>] ... [</system>] | dealx.ebnf |
| subsystem | [<subsystem Name>] ... [</subsystem>] | dealx.ebnf |
| connect | [<connect from="" to="" ... />] | dealx.ebnf (self-closing) |
| expose | [<expose path as="" />] | dealx.ebnf (self-closing) |
| traceability | [<traceability Name>] ... [</traceability>] | dealx.ebnf |
| satisfy | [<satisfy ...>] => {} ... [</satisfy>] | dealx.ebnf |
| validate | [<validate ...>] ... [</validate>] | dealx.ebnf |
| allocate | [<allocate ... />] | dealx.ebnf (self-closing) |

## Composition Attribute Names (inside tags)

| Attribute | Used In | Example |
|-----------|---------|---------|
| as | component instance, expose | as="battery" |
| from | connect, allocate | from="battery.hvOut" |
| to | connect, allocate | to="inverter.dcIn" |
| via | connect | via={HVDCCable { ... }} |
| carrying | connect | carrying={PowerDelivery { ... }} |
| requirement | satisfy, validate | requirement="REQ_SYS_001" |
| by | satisfy, validate | by="EVPlatform" |
| method | satisfy | method="simulation" |
| status | satisfy | status="partial" |
| relationship | allocate | relationship=<<derives>> |

## Delimiters and Punctuation

| Token | Usage |
|-------|-------|
| { } | block bodies, annotation bodies, object literals |
| ( ) | visibility wrappers, unit function calls, grouping |
| [ ] | multiplicity [4], [0..1], array literals |
| ; | statement terminator (required single-line) |
| , | separator in lists, imports, arrays |
| . | qualified name separator, path access |
| .. | multiplicity range (1..5) |
| :: | namespace access (Vehicle::mass) |
| : | type annotation (part engine : Engine) |
| = | value assignment |
| => | satisfy return type arrow |
| -> | connect from->to shorthand (reserved) |
| @ | annotation prefix |
| << >> | operator delimiters |
| [< | composition tag open |
| />] | composition tag self-close |
| [</ | composition tag close-open |
| >] | composition tag close-end |
| // | single-line comment |
| /* */ | block comment |
| /** */ | doc comment |
| ` | template literal delimiter |
| " | string literal delimiter |
| ' | string literal delimiter (alias) |
| ${ } | template interpolation |

## Arithmetic / Comparison Operators

| Operator | Meaning |
|----------|---------|
| + | addition |
| - | subtraction / negation |
| * | multiplication / zero-or-more multiplicity |
| / | division |
| >= | greater than or equal |
| <= | less than or equal |
| > | greater than |
| < | less than |
| == | equality |
| != | inequality |
