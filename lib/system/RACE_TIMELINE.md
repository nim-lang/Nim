# Race Condition Timeline Visualization

## The Bug: Thread Interleaving Leading to Use-After-Free

```
Time →   Thread T1 (Chunk Owner)              Thread T2 (Foreign Deallocator)
────────────────────────────────────────────────────────────────────────────────
t₀       [Operating normally]                 [Has cell1 allocated from T1's chunk]
         chunk.foreignCells = 0
         chunk.freeList = [cell2]

t₁                                            rawDealloc(cell1) called
                                              cell1.allocated = FALSE

t₂       rawDealloc(cell2) called
         All cells freed back to chunk!

t₃       Check can free chunk:
         ✓ freeList non-empty
         ✓ foreignCells == 0
         Decision: FREE THE CHUNK

t₄       ┌────────────────────┐
         │ RACE WINDOW OPENS  │              Read: chunk.owner == T1? YES
         └────────────────────┘              Decide: Add to T1's sharedFreeList

t₅       Execute freeBigChunk()               Prepare to add cell1 to list
         - listRemove from active chunks
         - chunk.owner = NULL                 ← T2 already read old value!
         - deallocate pages to OS
         🔥 CHUNK MEMORY FREED 🔥

t₆       [Chunk memory returned to OS]       atomicPrepend(T1.sharedFreeList, cell1)
         [Pages possibly reused]              ⚠️ Adding to FREED chunk's list!

t₇       [Later, T1 allocates again]

t₈       rawAlloc() called
         fetchSharedCells:
           cells = T1.sharedFreeList
           ← cells = [cell1]

t₉       for cell in cells:
           chunk = pageAddr(cell)             ← Reading FREED MEMORY!
           💀 USE-AFTER-FREE 💀

t₁₀      if chunk != activeChunk:
           foreignCells++                     ← Writing to FREED MEMORY!
           💀 HEAP CORRUPTION 💀
```

## Key Observations

### The Race Window (t₄ - t₅)

At time t₄, we have a **check-then-act race**:

| Thread T1                    | Thread T2                       |
|-----------------------------|---------------------------------|
| Read: `foreignCells == 0`   | Read: `chunk.owner == T1`       |
| ✓ Condition passes          | ✓ Condition passes              |
| Decide to free              | Decide to add to T1's list      |

**Neither thread knows about the other's decision!**

### The Atomicity Violation

```
T1's Operation:  [ Check foreignCells ] ──────────> [ Free Chunk ]
                                    ↑
                                    │ T2 observes stale state
                                    │
T2's Operation:  ────────────> [ Check owner ] ──> [ Add to sharedList ]
```

The gap between T1's check and T1's action allows T2 to observe **stale state**.

### Memory States

#### Before t₅ (Safe):
```
┌─────────────────────────────────┐
│ Chunk @ 0x1000 [ALLOCATED]      │
│  - owner: T1's MemRegion         │
│  - foreignCells: 0               │
│  - freeList: [cell2]             │
└─────────────────────────────────┘
         ↑
         │
T1.sharedFreeList: []
```

#### At t₅ (Danger):
```
T1 executes: freeBigChunk(chunk @ 0x1000)
OS deallocates pages [0x1000 - 0x2000)

┌─────────────────────────────────┐
│ Memory @ 0x1000 [FREED TO OS]   │  ← Undefined contents
│  - Could be zeroed               │
│  - Could be reused               │
│  - Could be unmapped             │
└─────────────────────────────────┘

T1.sharedFreeList: []                  ← Still empty
```

#### At t₆ (Corrupted):
```
┌─────────────────────────────────┐
│ Memory @ 0x1000 [FREED TO OS]   │  ← Already freed!
└─────────────────────────────────┘
         ↑
         │ cell1 points here!
         │
T1.sharedFreeList: [cell1]             ← Orphaned pointer
```

#### At t₉ (Crash):
```
T1 reads: chunk = pageAddr(cell1) = 0x1000
                                    ↑
                                    │ FREED MEMORY!
Access @ 0x1000:
  - Best case: Page zeroed → NULL deref → Immediate crash ✓
  - Worse case: Page reused → Read garbage → Delayed corruption 💀
  - Worst case: Page unmapped → Segmentation fault → Mystery crash 💣
```

## Why Traditional Testing Fails

### Timing Requirements

For the bug to manifest, all of these must align:

1. **T1 has exactly 0 foreign cells** (rare in active workload)
2. **T1's chunk appears "empty"** (all cells freed back)
3. **T2 starts dealloc** at exactly the right moment (nanosecond window)
4. **T1 and T2 interleave** in the 4-step sequence shown above
5. **T1 processes sharedFreeList** later (to trigger use-after-free)

**Probability**: ~ 1 in 10⁹ operations under normal load

### Symptoms Are Delayed

```
Bug occurs at t₆   →   Corruption appears at t₉   →   Crash happens later
     ↑                         ↑                            ↑
     │                         │                            │
  Invisible to T1          Invisible to T1              Stack trace
  and T2                   (no immediate crash)         points elsewhere
```

The stack trace when the crash happens shows T1 calling `fetchSharedCells`, but:
- The root cause (t₅) is in the past
- T2 is not in the stack trace
- The freed chunk is not visible
- Looks like a random memory corruption

### Heisenberg Effect

Adding debugging code changes timing:
- Logging → Changes scheduling
- Assertions → Changes memory layout
- ThreadSanitizer → Serializes operations (hides bug!)
- GDB breakpoints → Stops threads individually

**Result**: Bug disappears when you try to debug it!

## Formal Verification Advantage

TLA+ model checker explores **all possible interleavings**:

```
Traditional Testing:          Formal Verification:
─────────────────────────────────────────────────────
Test 1: [T1, T1, T2, T2]      Explore: [T1, T1, T2, T2]
Test 2: [T2, T2, T1, T1]      Explore: [T1, T2, T1, T2]  ← Finds bug!
Test 3: [T1, T2, T1, T2]      Explore: [T1, T2, T2, T1]
...                           Explore: [T2, T1, T1, T2]
Test 1M: Still not found      Explore: [T2, T1, T2, T1]
                              Explore: [T2, T2, T1, T1]

Success rate: 1 in 10⁹        Success rate: 100% (exhaustive)
Time: Years                   Time: <1 second
Confidence: Low               Confidence: Proof
```

## Comparison: Before and After Fix

### Current (Broken):

```nim
# No synchronization between check and free
if c.foreignCells == 0:
  freeBigChunk(c)  # ← Race!
```

### Fix Option 1: Epoch-Based (Correct):

```nim
let epoch = globalEpoch.fetchAdd(1)
if c.foreignCells == 0:
  # Wait for all threads to move past this epoch
  for t in threads:
    if t.threadEpoch <= epoch: return  # Wait
  freeBigChunk(c)  # ✓ Safe
```

**Timeline with fix**:
```
t₃  T1: epoch = 100, check passes
t₄  T2: entering dealloc, threadEpoch = 100
t₅  T1: Check if any thread has threadEpoch ≤ 100
         → T2 does! Don't free yet
t₆  T2: Add to sharedFreeList
t₇  T2: Exit dealloc, threadEpoch = 0
t₈  T1: Recheck, all threads past epoch 100
         → Safe to free now ✓
```

### Fix Option 2: Never Free (Correct):

```nim
if c.foreignCells == 0:
  # Don't free, just reuse
  discard  # ✓ Safe, chunk kept allocated
```

**No race possible** - chunks are never freed!

## Conclusion

This race condition is a textbook example of why **concurrent programming is hard**:

- ✗ Rare occurrence
- ✗ Delayed symptoms
- ✗ Invisible root cause
- ✗ Heisenberg debugging
- ✓ Found by formal verification

**Lesson**: Some bugs cannot be found by testing, only by formal proof.
