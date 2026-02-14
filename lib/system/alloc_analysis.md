# TLA+ Model of Nim's Multi-threaded Allocator

## Overview

This TLA+ specification models the critical multi-threaded aspects of `alloc.nim`, focusing on small chunk allocation with shared free lists and foreign cells. The model is designed to uncover subtle race conditions and memory management bugs that can occur in concurrent scenarios.

## What is Modeled

### Core Data Structures

1. **MemRegion per thread**:
   - `freeSmallChunks[thread]` - Active chunk for each thread
   - `sharedFreeLists[thread]` - Lock-free queue for cross-thread deallocation

2. **Chunk State**:
   - `chunkOwner` - Which thread created the chunk
   - `chunkFree` - Available capacity in bytes
   - `chunkForeignCells` - Count of cells from other chunks
   - `chunkFreeList` - List of free cells in the chunk
   - `chunkAcc` - Accumulator for fresh allocations

3. **Cell State**:
   - `cellOwner` - Which chunk created the cell
   - `cellAllocated` - Whether cell is currently in use

### Key Operations

1. **Alloc** (corresponds to `rawAlloc` for small chunks):
   - Try to allocate from active chunk's free list
   - Fall back to accumulator if no free cells
   - Fetch shared cells from `sharedFreeLists` (deferred cleanup)
   - Create new chunk if current chunk exhausted

2. **Dealloc** (corresponds to `rawDealloc` for small chunks):
   - If deallocating in owning thread:
     - Add to active chunk (if different from source) → creates **foreign cell**
     - OR add back to source chunk
     - Free chunk if completely empty AND no foreign cells
   - If deallocating in foreign thread:
     - Add to owner's `sharedFreeLists` (lock-free)

## Invariants Checked

### 1. NoLeakInvariant
```tla
(chunkOwner[c] = NULL) => (chunkForeignCells[c] = 0)
```
**What it checks**: A freed chunk cannot have foreign cells, as those cells would become inaccessible (memory leak).

**Real bug scenario**:
- Thread 1 creates chunk A
- Thread 1 deallocates cell from chunk B into chunk A (A gains foreign cell)
- Thread 1 tries to free chunk A prematurely
- If freed, the foreign cell from chunk B is lost forever

### 2. UniqueFreeListMembership
```tla
A cell cannot appear in multiple free lists simultaneously
```
**What it checks**: Double-free detection - a cell should only be in one free list at a time.

**Real bug scenario**:
- Thread 1 adds cell to active chunk's free list
- Thread 2 concurrently adds same cell to shared free list
- Both threads could allocate the same cell → corruption

### 3. NoAllocatedInFreeList
```tla
cellAllocated[cell] => (cell not in any free list)
```
**What it checks**: Use-after-free prevention - allocated cells must not be in free lists.

**Real bug scenario**:
- Thread 1 allocates cell C
- Thread 2 concurrently deallocates C (stale pointer?)
- C is both allocated and in a free list
- Thread 3 reallocates C while Thread 1 is still using it → corruption

### 4. ForeignCellsAccurate
```tla
chunkForeignCells[c] = actual count of foreign cells in c.freeList
```
**What it checks**: The foreign cell counter must match reality.

**Real bug scenario**:
- Incorrect foreign cell counting
- Chunk freed while foreignCells = 0 but actually has foreign cells
- Those foreign cells are now pointing to deallocated memory

## Known Issues in Real Implementation

### Issue 1: Shared List Race During compensateCounters

**Location**: [alloc.nim:809-826](alloc.nim#L809-L826)

```nim
proc compensateCounters(a: var MemRegion; c: PSmallChunk; size: int) =
  var it = c.freeList
  var total = 0
  while it != nil:
    inc total, size
    let chunk = cast[PSmallChunk](pageAddr(it))
    if c != chunk:
      inc c.foreignCells  # ← Race here!
    it = it.next
  inc(c.free, total)
  dec(a.occ, total)
```

**Problem**: Between fetching `sharedFreeLists` and processing them, another thread might:
1. Add more cells to the shared list
2. The active chunk might change
3. Foreign cell counts might become inconsistent

**TLA+ Detection**: The model will show interleavings where `foreignCells` becomes incorrect.

### Issue 2: Active Chunk Removal Race

**Location**: [alloc.nim:946-950](alloc.nim#L946-L950)

```nim
if c.free < size:
  listRemove(a.freeSmallChunks[s], c)
```

**Problem**:
- Chunk removed from active list
- Other threads still have pointers to it (via `sharedFreeLists` queue)
- Those threads might add cells AFTER chunk is "freed"
- If chunk is freed with `foreignCells = 0` check passing, but cells arrive later → leak

**TLA+ Detection**: Violates `NoLeakInvariant` - chunk freed with foreign references.

### Issue 3: Dealloc Lending Logic

**Location**: [alloc.nim:1030-1039](alloc.nim#L1030-L1039)

```nim
let activeChunk = a.freeSmallChunks[s div MemAlign]
if activeChunk != nil and c != activeChunk:
  f.next = activeChunk.freeList
  activeChunk.freeList = f
  inc(activeChunk.free, s)
  inc(activeChunk.foreignCells)
```

**Problem**: The source chunk's capacity is NOT decreased. This is intentional to prevent the source chunk from being freed. However:
- If the accounting is wrong, source chunk might appear "free" when it's not
- The "lending" mechanism creates complex dependencies between chunks
- A cycle of dependencies could prevent any chunk from being freed (memory leak)

**TLA+ Detection**: Model can find scenarios where chunks are never freed despite being logically empty.

### Issue 4: Atomic Prepend Weak Ordering

**Location**: [alloc.nim:789-798](alloc.nim#L789-L798)

```nim
template atomicPrepend(head, elem: untyped) =
  when hasThreadSupport:
    while true:
      elem.next.storea head.loada
      if atomicCompareExchangeN(addr head, addr elem.next, elem,
                                weak = true, ATOMIC_RELEASE, ATOMIC_RELAXED):
        break
```

**Problem**:
- Uses `ATOMIC_RELEASE` for success, `ATOMIC_RELAXED` for failure
- The `RELAXED` on failure might allow reordering
- On some architectures, this could lead to seeing stale values in the `next` pointer
- The `weak = true` makes it even more subtle (spurious failures allowed)

**TLA+ Note**: Standard TLA+ doesn't model memory models, but we can add assertions about the visibility of operations.

## How to Run the Model

### Prerequisites
- Install TLA+ Toolbox or command-line tools from: https://lamport.azurewebsites.net/tla/tools.html

### Running TLC Model Checker

```bash
# Using TLA+ Toolbox:
# 1. Open alloc.tla
# 2. Create a new model using alloc.cfg
# 3. Run TLC

# Using command line:
java -cp tla2tools.jar tlc2.TLC -config alloc.cfg alloc.tla
```

### Interpreting Results

**No errors**: Current parameter configuration doesn't expose bugs (but doesn't prove absence!)

**Invariant violated**: TLC will show:
- The invariant that failed
- A counterexample trace leading to the violation
- State values at each step

**Deadlock detected**: Indicates a scenario where no thread can progress (likely a logic bug)

### Tuning Parameters

Start small and increase:
```cfg
# Minimal (fast, catches obvious bugs)
Threads = {t1, t2}
MaxChunks = 2
MaxCells = 4

# Medium (good coverage)
Threads = {t1, t2, t3}
MaxChunks = 3
MaxCells = 6

# Large (thorough but slow)
Threads = {t1, t2, t3}
MaxChunks = 4
MaxCells = 8
```

## Potential Fixes

### Fix 1: Delay Chunk Freeing
Don't free chunks immediately. Keep a "pending free" list and only free when:
1. Chunk is completely empty
2. No foreign cells
3. No pending entries in any `sharedFreeLists`

### Fix 2: Epoch-Based Reclamation
Use epoch-based memory reclamation (like RCU):
- Each operation registers an epoch
- Chunks can only be freed after all threads have moved past the epoch

### Fix 3: Reference Counting
Add a reference count to each chunk:
- Increment when a cell is lent to another chunk
- Decrement when cell is actually processed from shared list
- Only free when refcount = 0

### Fix 4: Eliminate Foreign Cells
Simplify by never lending cells between chunks:
- Each thread keeps its own chunks
- Cross-thread deallocations always go to shared list
- Higher latency but simpler correctness argument

## Simplifications in the Model

The TLA+ model makes these simplifications for tractability:

1. **Single size class**: Real allocator has multiple size classes
2. **No big chunks**: Only models small chunk allocation
3. **No chunk coalescing**: Real allocator merges adjacent free chunks
4. **Simplified memory model**: Doesn't model weak memory ordering effects
5. **No page management**: Abstracts away OS page allocation
6. **Bounded resources**: Limited chunks and cells (real allocator can grow)

Despite these simplifications, the model captures the essential concurrent interaction patterns where bugs occur.

## Next Steps

1. **Run the model** with increasing parameters to find violations
2. **Analyze counterexamples** to understand the bug scenario
3. **Implement fixes** in the Nim code
4. **Re-verify** the model with fixes applied
5. **Add assertions** to the Nim code based on invariants
6. **Consider adding unit tests** based on counterexample traces

## References

- Original TLSF paper: http://www.gii.upv.es/tlsf/files/papers/tlsf_desc.pdf
- TLA+ documentation: https://lamport.azurewebsites.net/tla/tla.html
- Lock-free algorithms: "The Art of Multiprocessor Programming" by Herlihy & Shavit
