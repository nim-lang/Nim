# BIF symlink deduplication experiment

The Merenda `deps/.nimcache` examined on 2026-10-30 occupied 4.1 GiB on disk.
Grouping BIFs by exact SHA-256 content produced the following logical byte counts:

| Artifact | Files | Bytes | Duplicate files | Duplicate bytes |
| --- | ---: | ---: | ---: | ---: |
| Semantic `.s.bif` | 2,361 | 895,234,754 | 1,128 | 405,197,281 |
| Lowered `.t.bif` | 2,361 | 1,071,754,883 | 352 | 28,178,717 |
| Import `.s.deps.bif` | 2,361 | 1,347,386 | 1,354 | 688,451 |
| Edges `.edges.bif` | 2,361 | 355,235 | 1,653 | 200,604 |
| Interface `.iface.bif` | 2,361 | 188,880 | 127 | 10,160 |
| Implementation `.impl.bif` | 2,361 | 186,519 | 121 | 9,559 |

Duplicate bytes count all but one file in each equal-content group. This is an
upper bound on savings before filesystem allocation, symlinks, object-store
metadata, and retained unreferenced objects. No files were changed during the
analysis.

The semantic and lowered artifacts are the useful targets. Metadata sidecars
should remain independent. Sharing content must not imply reusing semantic
results across configurations: each configuration still compiles and compares
its own output.

## Freshness constraint

`nifmake` uses modification times to decide whether its inputs and outputs are
fresh, and its ordinary file timestamp lookup follows symlinks. A link to a
previously published hash object therefore inherits that object's modification
time, not the time at which this configuration produced its artifact. Merely
replacing a freshly built BIF with such a symlink can make a changed output look
older than its consumers, or make an old output appear newer than changed
inputs. Updating the shared object's timestamp also changes the apparent time
of every other link to it. Both approaches can silently skip necessary rebuilds.

The prototype uses independent per-artifact freshness timestamps in the
build scheduler. Production use also requires an audit of other timestamp checks, plus
atomic publication and replacement, safe concurrent writes, and a strategy for
unreferenced objects. It must never write through a symlink into a shared object.
The existing semantic writer uses a temporary file and rename, while the
lowered writer writes directly to its output path; both paths need review.
Tests should cover clean and no-op builds, changed and reverted bodies,
cross-configuration sharing, concurrent writers, missing/corrupt objects and
comparison to clean builds. Windows can retain the existing behavior.

## Prototype

On Unix, build the experimental scheduler and compiler, then enable the
experiment with `-d:icBifDedup` on `nim ic` or `nim track`:

```sh
bin/nim c -d:release -o:bin/nifmake_biflinks tools/nifmake_biflinks.nim
bin/nim c -o:bin/nim_biflinks compiler/nim.nim
bin/nim_biflinks ic -d:icBifDedup yourproject.nim
python3 tests/ic/bif_symlink_test.py bin/nim_biflinks
```

The driver requires the experimental scheduler next to the compiler when the
flag is set. The scheduler reads BIF symlink timestamps without following them
and treats missing targets as missing files. Writers publish content-addressed
objects under the nimcache's `bif-objects-v1` directory and atomically replace
individual BIF links. Only `.s.bif` and `.t.bif` use the store. They are still
produced independently under each configuration; this deduplicates storage,
not semantic compilation.

Object publication uses a hard link from a private temporary file and checks an
existing object byte-for-byte before reuse. Hash collisions or corrupt existing
objects fail compilation. Concurrent builds using the same artifact path still
have the usual IC cache concurrency limitations. Objects are not garbage
collected: deleting a configuration does not remove unreferenced objects. A
journal or index could support accounting and garbage collection, but its
updates and any deletion would need coordination with active readers and
writers. Direct object lookup already uses the content hash as the filename.
Do not use the ordinary nifmake against a cache containing these links.

## FigDraw frontend benchmark

On macOS, a release-built compiler ran `nim track` against
`/Volumes/projects/nims/figdraw/src/figdraw.nim` with eight jobs. Each mode used
an initially empty, separate cache. The second configuration adds the unused
`bifUnusedProbe` define; repeat runs that configuration again. Values are single
observations, sequentially run with potentially warm filesystem caches.

| Build | Baseline wall | Symlink wall | Baseline CPU | Symlink CPU |
| --- | ---: | ---: | ---: | ---: |
| First configuration | 93.979 s | 94.140 s | 110.082 s | 110.751 s |
| Second configuration | 79.556 s | 90.348 s | 95.425 s | 107.962 s |
| Repeat second configuration | 0.114 s | 0.174 s | 0.099 s | 0.168 s |

After both configurations, disk usage measured by `du` was 189,576 KiB for
the baseline and 108,024 KiB with symlinks: 81,552 KiB (43.0%) less for the
whole cache. Both runs generated 652 semantic BIF paths totaling 165,637,780
logical bytes. In the prototype, those 652 links pointed to 326 distinct
objects. The first configuration alone used 101,940 KiB and 101,936 KiB,
respectively. These are frontend-only results, not measurements of lowered
`.t.bif` artifacts or a full `nim ic` backend build. The extra time in the second
configuration includes hashing and byte comparison; the experiment does not
isolate their individual costs. No drawing test was run.

### In-memory hashing follow-up

The serializer already renders the complete BIF into an in-memory string and
patches its index-offset field before returning. The prototype now hashes this
finished buffer before writing it; it no longer writes and rereads a temporary
BIF to obtain the hash. If a matching object exists, it compares the buffer
against that object and does not write another BIF. Hashing is a separate pass
over the completed in-memory serialization, not incremental hashing during
rendering. The final index-offset patch would need to be accounted for by a
streaming design.

A subsequent single run with the same FigDraw setup and a freshly built
release compiler measured 73.860 s wall / 90.035 s CPU for the first
configuration, 71.193 s wall / 86.266 s CPU for the second configuration,
and 0.142 s wall / 0.141 s CPU for the repeat. Cache sizes were unchanged at
101,936 KiB after the first and 108,024 KiB after the second. The original
prototype's corresponding wall times were 94.140 s, 90.348 s and 0.174 s.
These unpaired single runs were made at different times, so changing filesystem
caches or machine load could explain part of the difference; they do not isolate
the optimization's speedup.

### Repeated in-memory hashing benchmark

Three fresh-cache trials per variant were run sequentially on the same macOS
host, with eight jobs and the same release-built compiler. Variant order was
baseline then symlink, symlink then baseline, and baseline then symlink. Each
trial built FigDraw's frontend in two configurations differing by the unused
`bifUnusedProbe` define, then ran the second configuration three more times.
OS filesystem caches were not cleared. Times below are wall-clock medians with
minimum–maximum in parentheses; no-op values cover nine runs per variant.

| Build | Baseline | Symlink |
| --- | ---: | ---: |
| First configuration (3 runs) | 70.60 s (69.70–70.88) | 76.00 s (75.71–76.04) |
| Second configuration (3 runs) | 67.82 s (66.89–67.96) | 73.36 s (72.24–73.45) |
| No-op (9 runs) | 91.9 ms (86.2–93.5) | 138.1 ms (133.9–157.5) |
| Cache after both configurations | 189,616 KiB | 108,064 KiB |

The median first and second builds were respectively 7.7% and 8.2% slower
with symlinks. The median no-op added 46 ms. The combined cache saved
81,552 KiB (43.0%). Each variant produced 652 semantic BIFs totaling
165,637,780 logical bytes; the symlink variant pointed to 326 distinct objects.

Both variants used the same compiler, but used different scheduler binaries:
the regular nifmake and the experimental link-aware nifmake. The latter was
built with the documented default compilation command. The measurements do not
isolate scheduler overhead from hashing, filesystem operations, or byte
comparison. This is a frontend-only experiment, with three fresh-cache samples
per variant and no drawing test.

### Writer profile and release scheduler

An opt-in compiler build with `-d:nimIcBifProfile` prints `BIFPROFILE` records
for semantic or lowered shared-object writes. Each record reports size and
nanoseconds spent in fresh-pool copying (`fresh`), BIF rendering (`render`),
hashing (`hash`), checking the current path (`check`), publishing or checking
an object (`publish`), and publishing the symlink (`link`). These are elapsed
intervals summed across compiler processes, not CPU time or build wall time;
parallel intervals can overlap. The profile itself adds timing and logging cost.

In two FigDraw frontend configurations with eight jobs, each produced 328
profiled writes totaling 82.8 MB. Summed elapsed times were:

| Phase | First configuration | Second configuration |
| --- | ---: | ---: |
| Fresh-pool copy and setup | 1.085 s | 1.095 s |
| Render | 0.111 s | 0.110 s |
| SHA-1 | 0.112 s | 0.111 s |
| Publish or compare object | 0.198 s | 0.119 s |
| Publish symlink | 0.067 s | 0.075 s |
| Whole shared writer | 1.580 s | 1.518 s |

The normal writer also copies pools and renders BIFs, so these totals are not
the incremental cost of deduplication. In this workload, hash, object and link
phases alone cannot explain the previously reported multi-second wall gap.

The earlier measurements used an unoptimized build of the experimental
scheduler. Rebuilding it with `-d:release` reduced the gap. Two fresh-cache
pairs were run in alternating order, using the same release-built compiler and
the existing regular scheduler for baseline. The regular scheduler's exact
build flags were not verified; `koch` normally builds it in release mode.
Filesystem caches were not cleared. This table shows both wall-time samples,
not a statistical estimate:

| Build | Baseline | Symlink, release scheduler |
| --- | ---: | ---: |
| First configuration | 69.56, 70.31 s | 71.30, 75.07 s |
| Second configuration | 67.57, 68.14 s | 71.54, 68.93 s |
| Cache after both | 189,728 KiB | 108,176 KiB |

The means were 69.93 vs 73.19 s for the first configuration and 67.85 vs
70.24 s for the second. This is a smaller difference than the earlier
unoptimized-scheduler results, but the two samples vary and do not establish
how much of the remaining difference comes from any particular component.
