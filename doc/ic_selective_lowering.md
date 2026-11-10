# Inline iterator implementation ownership

An inline iterator can contain a routine that captures an iterator local. Its
semantic definition belongs to the iterator's provider, but expansion and lambda
lifting happen in the consumer. Mutating the provider's nested routine in that
process is unsafe: the provider's independent lowering job may already have
published its unlifted body.

`privateIterator` in `compiler/transf.nim` gives each expansion a private mutable
implementation graph. It copies routine symbols, signatures, parameters, results,
and locals, and redirects references through one symbol map. Recursive references
are registered before their bodies are copied. Signature aliases are repaired
after copying the graph. Named source types and global storage keep their original
identity. Body reads use `getBody`, preserving dependency tracking.

The private graph is an implementation detail, not a new source routine. Every
nested routine copy retains its source routine's C linker name and carries
`sfIteratorImplementation`. Within a translation unit, `genProcLvl3` emits only
one body for that name. Across translation units, the existing cnif ownership
merge selects one definition and leaves declarations in the other consumers.
The private NIF symbols still belong to the consumers, so loading a lowered
consumer does not replace its lifted body with the provider's semantic body.

Lambda lifting precedes call-site argument substitution. Copies of the same
instantiated iterator therefore agree on the closure environment layout and
calling convention. Each execution still allocates its own environment. Sharing
the code does not share captured variables. Explicit global and static local
storage continues to refer to the original symbols.

This distinction matters for correctness as well as code size. Giving each copy
a distinct linker name changed ordinary procedure equality for noncapturing
routines. Restoring references to the original semantic symbols was insufficient:
a noncapturing factory may itself create a capturing closure and require a lifted
implementation. Keeping private lowered bodies with shared linkage handles both.

## Scheduling

Lowering remains partitioned by module. The frontend finishes before backend
lowering starts; `.bodydeps` records imported implementation dependencies.
Unused iterators are not expanded or speculatively capture-checked. A consumer
can introduce its first iterator use without requiring the provider to lower an
unused iterator ahead of time. Top-level expansion uses the same copying path.

The artifact version changes because the serialized routine flag and retained
linker name must survive the lower-to-codegen boundary.

## Regression coverage

The iterator metamorphic tests compare IC output with classic compilation,
exercise warm builds and no-op builds, and compare the final incremental build
with a clean rebuild:

- `tinlineiternestedclosure`: first use introduced and removed in the consumer.
- `tinlineitercaptureedits`: changed captured state with multiple importers.
- `tinlineiterunusedcapture`: unused invalid captures and recovery after errors.
- `tinlineiterprivategraph`: generic iterators, wrappers, recursion, escaping
  closures, multiple yields, top-level use, and shared storage.
- `tinlineiterroutineidentity`: procedure equality and closure code identity
  across call sites and modules, independent captured state, and noncapturing
  factories containing capturing closures.

The design preserves per-module scheduling; it does not claim a measured
improvement in compilation time or peak memory. Private graph copying still has
compile-time cost even when emitted routine bodies are shared.
