ORC/ARC Deterministic Memory Management Improvements
====================================================

Core Changes
------------
- `compiler/ccgtypes.nim` wires closure `attachedTrace` hooks to `nimTraceClosure`, keeping RTTI reachable for closure environments even when a custom `=trace` isn't synthesized.
- `compiler/liftdestructors.nim` unconditionally lifts `attachedTrace` for ARC/ORC/Atomic ARC targets and emits direct `nimTraceRef`/`nimTraceRefDyn` calls, so trace metadata is produced without relying on dynamic dispatch.
- `lib/system/cellseqs_v2.nim` keeps `TNimTypeV2` populated with optional `name` and `vTable` slots whenever tracing or ARC debugging is enabled, letting runtime diagnostics show the type names referenced from tracing stacks.
- `lib/system/cyclebreaker.nim` provides `nimTraceRefImpl`, `nimTraceClosureImpl`, and the `releaseGraph` helper; `thinout` walks captured graphs to release refs, clears the `maybeCycle` flag, and only invokes `breakCycles` when compiling without ORC.
- `lib/system/orc.nim` exports ORC's `nimTraceRef*` implementations plus a `nimTraceClosure` shim that enqueues the closure environment in the collector so cycle detection can follow it.
- `lib/system.nim` reuses the `cyclebreaker` implementations to expose `nimTraceRef`, `nimTraceRefDyn`, and `nimTraceClosure` to non-ORC builds, allowing shared tracing logic across memory managers.
- `lib/pure/asyncdispatch.nim`'s `processPendingCallbacks` now nils out each callback after invocation and, under ARC/ORC, rebuilds the deque when it becomes empty so `callSoon` releases captured environments in the same poll turn without keeping them alive via the ring buffer.
- `doc/mm.md` still describes closure cleanup via `cyclebreaker.thinout`; update it to match the callback-queue cleanup that the runtime actually performs.
- `tests/arc/tasync_callsoon_closure.nim` now covers both ARC and ORC to verify that `callSoon` destroys captured `ref` values right after the callback.
- `tests/arc/tasync_future_cycle.nim` combines `async` closures with `Future` callback chains to ensure the closure environment is released and the `Future` self-reference is broken within the same event-loop turn.
- `tests/arc/tasync_threaded_exception.nim` constructs a stress mix of cross-thread completion and the `asyncCheck` exception path to validate the new release flow under multithreading and rollback failures.
- `tests/arc/tasync_asynccheck_server.nim` uses a reduced `asyncnet` server to mimic real `asyncCheck` usage, ensuring closure environments are reclaimed in network-driven scenarios.
- `tests/arc/tasyncleak.nim`, `tests/arc/tasyncorc.nim`, and `tests/arc/thamming_orc.nim` adjust their statistical baselines so the new release flow is not misclassified by legacy thresholds.

Validation
----------
- `nim r --mm:arc tests/arc/tasync_callsoon_closure.nim`
- `nim r --mm:orc tests/arc/tasync_callsoon_closure.nim`
- `nim r --mm:arc tests/arc/tasync_future_cycle.nim`
- `nim r --mm:orc tests/arc/tasync_future_cycle.nim`
- `nim r --mm:arc tests/arc/tasync_asynccheck_server.nim`
- `nim r --mm:orc tests/arc/tasync_asynccheck_server.nim`
- `nim c --mm:orc -d:nimAllocStats tests/arc/tasyncleak.nim`
- `nim c --mm:orc -d:nimAllocStats tests/arc/thamming_orc.nim`
- `nim r --threads:on --mm:arc tests/arc/tasync_threaded_exception.nim`
- `nim r --threads:on --mm:orc tests/arc/tasync_threaded_exception.nim`
