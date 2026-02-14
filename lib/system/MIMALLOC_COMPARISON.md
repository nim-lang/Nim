# Comparison: Nim alloc.nim vs mimalloc

## Executive Summary

After analyzing mimalloc's source code, I found **both allocators have similar designs but mimalloc has additional protections** against the race condition we discovered. However, **mimalloc may still have a subtle race** in edge cases.

## Key Architectural Differences

### 1. Thread-Free List Structure

**Nim (alloc.nim)**:
```nim
# Per-thread, indexed by size class
sharedFreeLists: array[0..max, ptr FreeCell]
```
- Global array indexed by size class
- One list per size class per thread
- Cells from ANY chunk can be in this list

**mimalloc**:
```c
// Per-page atomic pointer
_Atomic(mi_thread_free_t) xthread_free;
```
- One list PER PAGE (not per size class)
- Only blocks from that specific page can be in its list
- Bottom bits used as delayed-free flags

**Impact**: mimalloc's per-page design is more granular and easier to reason about.

---

### 2. Free Counting Mechanism

**Nim**:
```nim
c.free: int32              # Available capacity in bytes
c.foreignCells: int        # Count of foreign cells
# Check: c.free == ChunkSize - overhead && foreignCells == 0
```
- Tracks free capacity in bytes
- Separate counter for foreign cells
- Two conditions must be checked

**mimalloc**:
```c
uint16_t used;             # Blocks currently in use
uint16_t capacity;         # Total blocks in page
// Check: page->used == 0
```
- Tracks blocks IN USE (not free)
- Single counter, simpler check
- `used` decremented when collecting thread_free

**Impact**: mimalloc's `used` counter is more reliable because it's updated atomically during thread_free collection.

---

### 3. Page Retirement Strategy

**Nim (Original)**:
```nim
# Immediate free when conditions met
if c.free == ChunkSize-overhead and c.foreignCells == 0:
  freeBigChunk(a, c)  # ← Race here!
```

**Nim (Our Fix)**:
```nim
# Never free small chunks
# Keep for reuse
```

**mimalloc**:
```c
void _mi_page_retire(mi_page_t* page) {
  // Don't retire if it's the only page in queue
  if (pq->last==page && pq->first==page) {
    page->retire_expire = MI_RETIRE_CYCLES;  // Delay freeing
    return;
  }
  _mi_page_free(page, pq, false);
}
```
- Pages have a `retire_expire` counter (16 cycles)
- Only retired page is freed after countdown
- Prevents thrashing (alloc/free/alloc cycles)

**Impact**: mimalloc's retirement gives a grace period, reducing race window.

---

### 4. Atomic Operations

**Nim**:
```nim
template atomicPrepend(head, elem: untyped) =
  when hasThreadSupport:
    while true:
      elem.next.storea head.loada
      if atomicCompareExchangeN(addr head, addr elem.next, elem,
                                weak = true, ATOMIC_RELEASE, ATOMIC_RELAXED):
        break
```
- CAS loop with ATOMIC_RELEASE/RELAXED
- `weak = true` allows spurious failures

**mimalloc**:
```c
do {
  mi_block_set_next(page, block, mi_tf_block(tfree));
  tfreex = mi_tf_set_block(tfree, block);
} while (!mi_atomic_cas_weak_release(&page->xthread_free, &tfree, tfreex));
```
- Similar CAS loop
- Also uses weak CAS with release semantics
- Additional delayed-free flags in bottom bits

**Impact**: Both use similar atomic patterns, no significant difference here.

---

## The Race Condition: Does mimalloc have it?

### The Scenario

```
T1: Check page->used == 0                → TRUE
T2:     Start mi_free_block_delayed_mt
T2:     CAS to add block to xthread_free → SUCCESS
T1: Call _mi_page_free(page)             → Page freed!
T2:     Block now in freed page's list   → Orphaned!
```

### Analysis

**Question**: Can this happen in mimalloc?

Let me trace through mimalloc's code:

1. **When is `page->used` checked?**
   - In `mi_page_all_free(page)` returns `page->used == 0`
   - Called before `_mi_page_retire()` or `_mi_page_free()`

2. **When is `page->used` decremented?**
   - In `_mi_page_thread_free_collect()`:
     ```c
     page->used -= (uint16_t)count;
     ```
   - This happens when collecting from `xthread_free`

3. **The Race Window**:
   ```
   T1: Check page->used == 0        (no atomic sync with xthread_free!)
   T2: Add to xthread_free          (doesn't update page->used!)
   T1: Free page
   ```

**Conclusion**: mimalloc **MAY have the same race condition**, but it's much less likely due to:

1. **Retirement delay**: `retire_expire` counter gives 16 alloc cycles before freeing
2. **Per-page lists**: Smaller race window (only affects one page, not all chunks of a size class)
3. **Frequent collection**: `_mi_page_free_collect` called often, updating `page->used` more frequently

However, the **fundamental race still exists** in mimalloc's design between:
- Checking `page->used`
- Another thread adding to `xthread_free` (which doesn't atomically update `used`)

---

## Additional Observations

### 1. Corruption Detection

**mimalloc** (free.c:204-210):
```c
// find the tail -- also to get a proper count (without data races)
size_t max_count = page->capacity;
size_t count = 1;
// ...
if (count > max_count) {
  _mi_error_message(EFAULT, "corrupted thread-free list\n");
  return; // don't process corrupted list
}
```

**Nim**: No equivalent check!

**FINDING**: Nim should add corruption detection when processing sharedFreeLists.

---

### 2. Delayed Free Mechanism

**mimalloc** uses a two-tier approach:
```c
page->xthread_free         // Per-page thread-free list
heap->thread_delayed_free  // Per-heap fallback list
```

When `xthread_free` is full or page is in full queue, blocks go to `thread_delayed_free` instead.

**Nim**: Only has `sharedFreeLists`, no fallback mechanism.

**FINDING**: Consider adding a fallback list for when sharedFreeLists grow too large.

---

### 3. Page Full/Empty Transitions

**mimalloc** tracks page states:
- Empty page (`used == 0`)
- Full page (`used == capacity`)
- Partial page (between)

Pages move between queues based on state transitions.

**Nim**: Chunks stay in `freeSmallChunks[s]` regardless of fullness, removed only when exhausted.

**FINDING**: Nim's approach is simpler but less sophisticated.

---

## Recommendations for Nim

### 1. Add Corruption Detection (High Priority)

```nim
proc compensateCounters(a: var MemRegion; c: PSmallChunk; size: int) =
  var it = c.freeList
  var total = 0
  var count = 0
  let maxCount = (SmallChunkSize - smallChunkOverhead()) div size

  while it != nil:
    inc count
    if count > maxCount:  # ← ADD THIS CHECK
      # Corrupted list (double-free or memory corruption)
      sysAssert(false, "corrupted shared free list")
      return
    inc total, size
    # ... rest of logic
```

**Justification**: Protects against memory corruption and double-free bugs.

---

### 2. Consider Using a `used` Counter (Medium Priority)

Instead of tracking `c.free` (capacity available), track `c.used` (blocks in use):

```nim
type SmallChunk = object
  used: int32     # Blocks currently allocated (not free)
  capacity: int32 # Total blocks in chunk
  # Remove: free, foreignCells
```

**Benefits**:
- Simpler logic: `used == 0` means completely free
- Atomic update during fetchSharedCells
- Matches mimalloc's proven design

**Tradeoff**: Requires refactoring allocation logic.

---

### 3. Add Retirement Delay (Low Priority)

If we want to eventually free chunks:

```nim
type SmallChunk = object
  # ... existing fields
  retireExpire: int  # Countdown before actually freeing

proc tryFreeChunk(c: PSmallChunk) =
  if c.retireExpire > 0:
    dec c.retireExpire
    return  # Not yet
  # Now actually free
  freeBigChunk(a, cast[PBigChunk](c))
```

**Benefits**: Reduces race window, prevents alloc/free thrashing.

---

### 4. Our Current Fix is Still Correct

Our fix (never free small chunks) is **MORE conservative than mimalloc** and therefore **SAFER**.

- mimalloc: Still has the race (mitigated by retirement delay)
- Nim (our fix): Race eliminated entirely (no freeing)

If mimalloc's race ever manifests, they would likely adopt a similar fix.

---

## Potential Bugs in Nim Not Present in mimalloc

### Bug 1: Missing Corruption Detection

**Location**: `compensateCounters` (line 809-826)

**Issue**: No check for list corruption (cycles, excessive length)

**Fix**: Add `maxCount` check (see Recommendation #1 above)

---

### Bug 2: Incorrect Capacity Accounting

**Location**: Lending cells between chunks (line 1036-1039)

**Issue**: When T1 lends cell to T2's active chunk:
```nim
inc(activeChunk.free, s)           # T2's chunk gains capacity
inc(activeChunk.foreignCells)      # T2 tracks as foreign
# But T1's chunk capacity is NOT decreased!
```

This is intentional (prevents T1's chunk from being freed), but creates an imbalance:
- Sum of all chunk capacities > actual memory allocated
- Could lead to memory accounting errors

**mimalloc approach**: Uses `page->used` counter which is always exact.

**Fix**: Consider tracking `used` instead of `free` (see Recommendation #2).

---

### Bug 3: Unbounded SharedFreeLists Growth

**Location**: Cross-thread deallocation (line 1060)

**Issue**: No limit on `sharedFreeLists` size. If one thread allocates and another thread deallocates continuously:
```nim
# Thread T1: allocate 1 million cells
for i in 1..1_000_000:
  cells[i] = alloc(size)

# Thread T2: deallocate all of them
for i in 1..1_000_000:
  dealloc(cells[i])  # All go to T1's sharedFreeLists!
```

T1's `sharedFreeLists[size]` now has 1 million cells. Next allocation by T1 calls `compensateCounters` which walks the entire list (O(n) = 1 million iterations!).

**mimalloc approach**: Uses per-page lists (bounded by page capacity) + fallback to `heap->thread_delayed_free`.

**Fix**: Add a threshold and fallback mechanism:
```nim
const MaxSharedListSize = 1024

proc addToSharedFreeList(c: PSmallChunk; f: ptr FreeCell; size: int) =
  # Check list size (approximate, non-atomic is OK)
  var count = 0
  var it = c.owner.sharedFreeLists[size]
  while it != nil and count < MaxSharedListSize:
    inc count
    it = it.next

  if count >= MaxSharedListSize:
    # Fallback: add to a global overflow list
    atomicPrepend globalOverflowFreeList, f
  else:
    # Normal path
    atomicPrepend c.owner.sharedFreeLists[size], f
```

---

## Conclusion

### Summary Table

| Aspect | Nim alloc.nim | mimalloc | Winner |
|--------|---------------|----------|--------|
| **Race condition** | Present (fixed by us) | Likely present | Nim (after fix) |
| **Corruption detection** | ❌ Missing | ✅ Present | mimalloc |
| **Capacity accounting** | Complex (free + foreignCells) | Simple (used counter) | mimalloc |
| **Retirement strategy** | None (our fix: never free) | Delayed with countdown | Tie |
| **List granularity** | Per size-class | Per page | mimalloc |
| **Unbounded growth** | Possible | Protected | mimalloc |

### Action Items

1. ✅ **DONE**: Fix race condition (never free small chunks)
2. 🔴 **HIGH**: Add corruption detection in `compensateCounters`
3. 🟡 **MEDIUM**: Add threshold to prevent unbounded `sharedFreeLists` growth
4. 🟡 **MEDIUM**: Consider refactoring to `used` counter (mimalloc style)
5. 🟢 **LOW**: Add retirement delay if memory return is needed

### Final Verdict

**Our fix is sound** and arguably **more conservative than mimalloc**. However, mimalloc has better **defensive programming** (corruption detection, bounded lists). We should adopt those improvements.

The fundamental race condition exists in both allocators' designs. mimalloc mitigates it with retirement delays; we eliminate it by never freeing. Both approaches are valid.
