# Kosmo cold IC build experiment

The workload is Kosmo 0.32.2, Merenda commit
`64a11015cfebfe46a90064d9b06d8dd21a2f9584`, on FreeBSD 15.1 amd64 with
Clang 19.1.7, 16 build jobs, release optimization, and native debug information.
The host is an AMD Ryzen 7 8745HS with 16 logical CPUs and 16 GB RAM.
The compiler baseline is `0b939a9d057814cf45835a8423c5c7eef3568967`.
Except for the import-sidecar comparison, each timed build starts in a separate
empty nimcache. Successful builds link
and run `kosmo --help`. These are cold compiler caches, with no claim that the
operating system's file cache has been flushed.

## What the profile found

The original build took 188.3 seconds: 101.1 seconds before the backend,
17.0 lowering, 20.0 generating C, 5.6 merging/rendering C, and 44.5 compiling
and linking native code. It launched 7,324 semantic workers over 20 discovery
rounds. Many workers only rediscovered that an import was unavailable.

Backend instrumentation attributed 345 summed worker-seconds to loading
dependency closures, including 131 seconds constructing interface tables.
Those times are nested worker totals, not additional wall-clock stages.

## Implemented changes

1. **Defer consumers of incomplete discovery rules.** A semantic worker can
   successfully record a newly discovered dependency without producing its
   semantic BIF. The scheduler propagates that deferred state through the
   current DAG while continuing independent work. The driver rebuilds the
   graph for the next round as before. The opt-in protocol is
   `NIFMAKE_DEFER_MISSING_OUTPUTS=nim_m`, supplied only to frontend scheduler
   invocations. Older schedulers ignore it and retain the existing behavior.
   Discovery still takes 20 rounds on this workload; the improvement removes
   redundant consumers within a round rather than predicting imports earlier.
2. **Construct backend interfaces on first lookup.** Loading hooks, replay
   actions, and dependency metadata does not require constructing every public
   symbol table. Backend modules leave that table pending; lookup reconstructs
   it from the stored ordered interface. The system module's explicit
   `AlwaysLoadInterface` request remains eager. Private-interface dependency
   tracking and public/private overload ordering are preserved.
3. **Share closure loading across four codegen modules.** The existing batch
   machinery now uses four modules per codegen worker by default; lowering
   retains its independent per-module partition.
   Generic instances are routed by their persisted module identity, matching
   the home that seeds their bodies. The declaring module in an instance's
   owner chain can differ from that home; routing by the owner chain caused
   undefined symbols when the two modules shared a batch. The default emit
   stage still renders all artifacts in one process.

   The broader IC suite exposed a separate serialization bug when lowering
   several modules together: backend symbol definitions were deduplicated by
   numeric item ID even though different members reuse those module-local IDs.
   A generated hook's parameter definition could disappear. The fix keys both
   symbol writer paths by their serialized `(name, disambiguator)` identity.
   It is isolated in [PR #26783](https://github.com/nim-lang/Nim/pull/26783),
   together with a batched regression that fails before the fix and passes
   with C and C++ afterward. This correctness fix changes no batching defaults.

   With that fix applied, the fully batched IC suite passes 93 of 94 tests.
   `tinlineiterunusedcapture` still exposes a separate diagnostic-order issue:
   an illegal capture is accepted after a consumer lowers the shared iterator.
   The final default therefore leaves lowering isolated.

`-d:icBatchSize:1` restores per-module backend workers for comparison.
An explicit batch-size define also partitions emit; the default keeps emit in
one process.

## Measurements

Initial measurements, one run per row:

| Configuration | Frontend handoff | Full build | Semantic workers | Lower / codegen workers |
| --- | ---: | ---: | ---: | ---: |
| Stock, empty cache | 101.1 s | 188.3 s | 7,324 | 1,134 / 1,134 |
| Deferred scheduler, empty cache | 66.5 s | 154.3 s | 1,158 | 1,134 / 1,134 |
| Lazy interfaces, stock scheduler | 101.9 s | 177.8 s | 7,324 | 1,134 / 1,134 |
| Scheduler + lazy interfaces + explicit batch size 4 | 66.4 s | 135.0 s | 1,158 | 285 / 285 |
| Final default: scheduler + lazy interfaces + codegen batches | 66.3 s | 138.2 s | 1,158 | 1,134 / 285 |
| Stock with import sidecars preloaded | 51.2 s | 138.0 s | 1,106 | 1,134 / 1,134 |

The final row is a discovery comparison, not a genuinely empty cache. It
reuses only semantic import sidecars and the cache version, with no semantic
BIFs, generated C, objects, or executable. Its 1,148 generated C files match
stock byte for byte.

Lazy interfaces alone reduced lowering to 11.7 seconds and codegen to 13.7
seconds. With batching, those stages took 6.8 and 8.1 seconds respectively.
The combined experimental build was 28.3% faster end to end than the original
run. Its lowering partition remains experimental. The final configuration also
includes the serializer fix and retains a single emit worker.

The first final-default run took 138.2 seconds, a 26.6% reduction from stock,
with 11.7 seconds lowering and 8.4 seconds generating C. This matches the old
import-list-preloaded comparison while starting with an actually empty cache.

The repeated comparison uses the final correctness-preserving grouping: one
module per lowering worker, four per codegen worker, and one emit process.
Each run uses a separate empty compiler cache and the same 16-job release/debug
configuration. No tests or compiler rebuilds run alongside the timed builds.

| Configuration | Run 1 | Run 2 | Mean |
| --- | ---: | ---: | ---: |
| Stock | 188.3 s | 190.3 s | 189.3 s |
| Final default | 138.2 s | 138.5 s | 138.3 s |

The mean reduction is **26.9%, or 51.0 seconds**. All four builds linked and
passed `kosmo --help`. These are two samples per configuration, not a broad
statistical benchmark. Exact values are recorded in `final-comparison.json`
beside the raw run artifacts.

The fresh instrumented build took 139.9 seconds and passed the smoke check.
Its backend worker totals, compared with the original diagnostic run, are:

| Backend quantity | Original | Final default |
| --- | ---: | ---: |
| Dependency-closure loading | 345.1 worker-s | 123.8 worker-s |
| Public-interface symbol insertions | 119,410,641 | 1,858,078 |
| BIF loads | 445,143 | 301,205 |

Closure loading fell 64.1%. The interface count fell 98.4%; this does not mean
interface construction has zero cost, since per-process millisecond rounding
hides small remaining table builds. Detailed phase totals are saved in
`profile-comparison.txt` and `backend-profile-comparison.json`.

The remaining wall time is concentrated in the roughly 66-second frontend and
46-second native compile/link stage. The final semantic graph's measured
critical chain contains 84 rules and about 41 seconds of semantic work.
Delayed imports repeatedly occur behind SIMD and window-backend guards that
use named constants; these are a concrete target for earlier dependency
discovery. The preloaded-import comparison measures the opportunity without
claiming that those edges can already be discovered statically.

## Correctness and reproducibility

The interface round-trip test covers public, private, mixed, empty, and
overloaded interfaces across table growth boundaries, including deferred public
construction. The batch regression reproduces an undefined generic-instance
symbol before the routing fix; it checks C and C++ cold builds, cache reuse,
and an edit to the generic body after the fix. Companion scheduler tests check
serial/parallel execution, independent work, descendant withholding, subsequent
release, and the default behavior without the opt-in variable.

The main checkout was rebuilt in release mode. Focused compiler tests are
`ticinterface`, `ticloweredinterface`, `tichiddeninterface`, `ticbatchownership`,
`ticspeculativeimports`, and `ticguardcycle`. The full `tests/ic` category also
checks clean/incremental equivalence and compares runtime output with classic
compilation. The dynlib fixture now selects FreeBSD's `libc.so.7` on FreeBSD.
The final selected configuration passed all 94 tests in the IC category.
All six focused compiler tests and the companion scheduler tests also pass.
After the isolated serializer fix, focused closure, ownership, destructor,
and async regressions pass with batched lowering as well.

Lazy loading changes file-index allocation order. Resolving generated `FX_*`
file macros makes 1,147 of 1,148 C files exactly equal to stock; the remaining
GLX file differs in generated temporary names. Raw C byte identity is therefore
not claimed for this optimization. Full-build checks and runtime regressions
provide the behavioral validation.

Both final-default cold runs produced 1,147 generated C files, byte for byte
identical between the two runs, and identical help output. Codegen batching
changes definition placement and splitting relative to stock, so the final
configuration does not claim byte identity with stock C output.

The scheduler change belongs to Nimony. Because `dist/nimony` is an ignored
dependency checkout, its source and test changes are also exported in
[`tools/nifmake-defer-missing-outputs.patch`](../tools/nifmake-defer-missing-outputs.patch).
For a fresh checkout at the pinned Nimony revision, apply and rebuild it:

```sh
git -C dist/nimony apply ../../tools/nifmake-defer-missing-outputs.patch
bin/nim c -d:release --out:bin/nifmake dist/nimony/src/nifmake/nifmake.nim
bin/nim c -d:release --out:bin/nim-cold compiler/nim.nim
```

The Nimony pin has not been changed to an unpublished commit. Without the
companion patch, the lazy-loading and batching changes still work, while
frontend scheduling retains its previous cost.

Build the workload from the Merenda directory, retaining its Atlas configuration:

```sh
/path/to/Nim/bin/nim-cold c --ic:on --parallelBuild:16 --colors:off \
  --nimcache:/new/empty/cache --out:/new/run/kosmo src/merenda/kosmo/kosmo.nim
/new/run/kosmo --help
```

Local raw measurements, process spans, build logs, source patches, manifest,
and analysis scripts are in
`/home/elcritch/projs/nims/kosmo-ic-profile.7JoMoG`.
