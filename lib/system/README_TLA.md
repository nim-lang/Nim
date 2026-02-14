# TLA+ Formal Verification of alloc.nim

This directory contains TLA+ specifications for formally verifying the multi-threaded memory allocator in `alloc.nim`.

## Quick Start

### Option 1: Focused Model (Start Here!)

The focused model (`alloc_focused.tla`) isolates the **most critical race condition** in a minimal scenario:

```bash
# This should find a violation in seconds
tlc alloc_focused.tla -config alloc_focused.cfg
```

**Expected Result**: TLC will find a counterexample showing:
1. Thread T1 checks if chunk can be freed (foreignCells = 0 ✓)
2. Thread T2 starts deallocating a cell belonging to T1's chunk
3. Thread T1 frees the chunk (appears safe)
4. Thread T2 adds cell to T1's sharedFreeList
5. **BUG**: Chunk freed but cell is orphaned in sharedFreeList → memory leak

### Option 2: Full Model

The full model (`alloc.tla`) covers more scenarios but requires more computing resources:

```bash
tlc alloc.tla -config alloc.cfg -workers 4
```

This can take minutes to hours depending on the constants in `alloc.cfg`.

## The Critical Bug

### The Race Condition

```nim
# Thread T1 (owner of chunk C):
if c.free == SmallChunkSize - smallChunkOverhead() and c.foreignCells == 0:
    # ← T2 can be here simultaneously!
    listRemove(a.freeSmallChunks[s div MemAlign], c)
    c.size = SmallChunkSize
    freeBigChunk(a, cast[PBigChunk](c))  # Chunk C is freed

# Thread T2 (deallocating a cell from chunk C):
if c.owner == addr(a):
    # ... local dealloc path
else:
    # c.owner points to T1
    addToSharedFreeList(c, f, s div MemAlign)  # ← After C is freed!
```

### The Problem

The check `c.foreignCells == 0` in Thread T1 is **not atomic** with respect to Thread T2 adding cells to `sharedFreeLists`. The cell is "in flight" and not yet counted as foreign.

### Timeline of the Bug

```
T1: Read c.foreignCells                  = 0 ✓
T2:     Check c.owner                    = T1 ✓
T1: Read c.free                           = ChunkSize ✓
T1: Decide to free chunk C
T2:     Prepare to add cell to sharedFreeLists[T1]
T1: Free chunk C                          ← chunk deallocated
T2:     Add cell to sharedFreeLists[T1]   ← cell orphaned!
T1: Later fetch sharedFreeLists[T1]
T1: Call pageAddr(cell)                   ← accesses freed memory!
```

### Real-World Impact

This is extremely hard to reproduce because:
- The race window is nanoseconds wide
- Requires precise timing of 3 operations across 2 threads
- Symptoms appear much later (use-after-free, corruption)
- Heap corruption may not crash immediately
- May only trigger under heavy load or specific allocation patterns

This is exactly why **formal verification is valuable** - it finds these impossible-to-debug race conditions.

## Proposed Fixes

### Fix 1: Epoch-Based Reclamation (Recommended)

```nim
type
  Epoch = object
    value: Atomic[uint64]

var globalEpoch: Epoch
threadvar threadEpoch: uint64

proc enterCriticalSection() =
  threadEpoch = globalEpoch.value.load()

proc exitCriticalSection() =
  threadEpoch = 0

proc canFreeChunk(c: PSmallChunk): bool =
  # Check foreign cells
  if c.foreignCells != 0:
    return false

  # Check if any thread is in a critical section from before we checked
  let epoch = globalEpoch.value.fetchAdd(1)
  for t in allThreads:
    if t.threadEpoch != 0 and t.threadEpoch < epoch:
      return false  # Thread might still be adding to our shared list

  return true
```

### Fix 2: Never Free Small Chunks (Simple)

```nim
# Don't free small chunks, only reuse them
if c.free == SmallChunkSize - smallChunkOverhead() and c.foreignCells == 0:
  # Instead of freeBigChunk:
  # listAdd(a.dormantSmallChunks, c)  # Keep for reuse
  discard  # Just leave it in the active list
```

**Pros**: Simple, no races, chunks are reused
**Cons**: Memory not returned to OS, higher memory usage

### Fix 3: Reference Counting

```nim
type SmallChunk = object
  # ... existing fields
  refCount: Atomic[int]  # New field

# When lending a cell to another chunk:
atomicInc(sourceChunk.refCount)

# When processing shared list:
for cell in sharedCells:
  let sourceChunk = pageAddr(cell)
  atomicDec(sourceChunk.refCount)

# When checking if can free:
if c.refCount == 0 and c.foreignCells == 0:
  freeBigChunk(a, cast[PBigChunk](c))
```

**Pros**: Precise tracking
**Cons**: More atomic operations (performance cost), more complex

### Fix 4: Delayed Free with Grace Period

```nim
type PendingFree = object
  chunk: PSmallChunk
  freeAt: MonoTime

var pendingFrees: seq[PendingFree]

const GracePeriod = initDuration(milliseconds = 10)

proc tryFreeChunk(c: PSmallChunk) =
  pendingFrees.add PendingFree(
    chunk: c,
    freeAt: getMonoTime() + GracePeriod
  )

proc processPendingFrees() =
  let now = getMonoTime()
  for i in countdown(pendingFrees.len - 1, 0):
    if pendingFrees[i].freeAt <= now:
      let c = pendingFrees[i].chunk
      if c.foreignCells == 0:  # Recheck
        freeBigChunk(a, cast[PBigChunk](c))
      pendingFrees.del(i)
```

**Pros**: Simple, eventually frees memory
**Cons**: Memory held longer, arbitrary grace period

## Verification Strategy

### Phase 1: Model the Bug (✓ Done)
- [x] Create TLA+ model of critical section
- [x] Find counterexample showing the race
- [x] Understand the failure scenario

### Phase 2: Verify the Fix
1. Choose a fix (recommend Fix 1 or Fix 2)
2. Update TLA+ model to include the fix
3. Run TLC to verify invariants hold
4. If violations found, refine the fix

### Phase 3: Implementation
1. Implement fix in alloc.nim
2. Add assertions based on TLA+ invariants
3. Run existing test suite
4. Add stress tests based on counterexample traces

### Phase 4: Validation
1. Run under ThreadSanitizer
2. Run stress tests for extended periods
3. Consider formal proof for critical paths

## Understanding TLA+ Output

### No Violations Found
```
Model checking completed. No error has been found.
States analyzed: 1234 distinct states.
```
**Meaning**: For the given parameters, no bugs found. Does NOT prove absence for all inputs!

### Invariant Violation
```
Error: Invariant NoLeakInvariant is violated.

State 1: ...
State 2: ...
State 3: [ERROR state with violation]
```
**Action**: Examine the state trace to understand the interleaving that causes the bug.

### Deadlock
```
Error: Deadlock reached.
```
**Meaning**: All processes stuck, cannot progress. Usually indicates a logic error (e.g., waiting for a condition that can never be true).

## Files in This Directory

- **alloc.tla** - Full model with allocation and deallocation
- **alloc.cfg** - Configuration for full model (3 threads, multiple chunks)
- **alloc_focused.tla** - Minimal model showing the critical race
- **alloc_focused.cfg** - Configuration for focused model (2 threads, 1 chunk)
- **alloc_analysis.md** - Detailed analysis of potential bugs
- **README_TLA.md** - This file

## Further Reading

- **TLA+ Introduction**: Leslie Lamport's video course
  https://lamport.azurewebsites.net/video/videos.html

- **Practical TLA+**: Hillel Wayne's book
  https://www.apress.com/gp/book/9781484238288

- **Lock-Free Programming**: Preshing on Programming
  https://preshing.com/20120612/an-introduction-to-lock-free-programming/

- **Memory Models**: "Threads Cannot be Implemented as a Library" by Boehm
  https://dl.acm.org/doi/10.1145/1065010.1065042

## Contact

For questions about these specifications or if you find issues, please file a bug report with:
- The TLA+ model used
- The TLC configuration
- The counterexample trace (if applicable)
- Your interpretation of the bug

This will help improve both the allocator and the formal models.
