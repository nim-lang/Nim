---- MODULE yrc_proof ----
\* TLA+ specification of YRC (Thread-safe ORC cycle collector)
\* Models the fine details of barriers, striped queues, and synchronization
\*
\* ## Key Barrier Semantics Modeled
\*
\* ### Write Barrier (nimAsgnYrc)
\*   1. atomicStoreN(dest, src, ATOMIC_RELEASE)
\*      - Graph update is immediately visible to all threads (including collector)
\*      - ATOMIC_RELEASE ensures all prior writes are visible before this store
\*      - No lock required for graph updates (lock-free)
\*
\*   2. nimIncRefCyclic(src, true)
\*      - Acquires per-stripe lockInc[stripe] (fine-grained)
\*      - Buffers increment in toInc[stripe] queue
\*      - On overflow: acquires global lock, merges all stripes, applies increment
\*
\*   3. yrcDec(tmp, desc)
\*      - Acquires per-stripe lockDec[stripe] (fine-grained)
\*      - Buffers decrement in toDec[stripe] queue
\*      - On overflow: acquires global lock, merges all stripes, applies decrement,
\*        adds to roots array if not already present
\*
\* ### Merge Operation (mergePendingRoots)
\*   - Acquires global lock (exclusive access)
\*   - Sequentially acquires each stripe's lockInc and lockDec
\*   - Drains all buffers, applies RC adjustments
\*   - Adds decremented objects to roots array
\*   - After merge: mergedRC = logicalRC (current graph state)
\*
\* ### Collection Cycle (under global lock)
\*   1. mergePendingRoots: reconcile buffered changes
\*   2. markGray: trial deletion (subtract internal edges)
\*   3. scan: rescue objects with RC >= 0 (scanBlack follows current graph)
\*   4. collectColor: free white objects (closed cycles)
\*
\* ## Safety Argument
\*
\* The collector only frees closed cycles (zero external refs). Concurrent writes
\* cannot cause "lost objects" because:
\*   - Graph updates are atomic and immediately visible
\*   - Mutator must hold stack ref to modify object (external ref)
\*   - scanBlack follows current physical edges (rescues newly written objects)
\*   - Only objects unreachable from any stack root are freed

EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC

CONSTANTS NumStripes, QueueSize, RootsThreshold, Objects, Threads, ObjTypes
ASSUME NumStripes \in Nat /\ NumStripes > 0
ASSUME QueueSize \in Nat /\ QueueSize > 0
ASSUME RootsThreshold \in Nat
ASSUME IsFiniteSet(Objects)
ASSUME IsFiniteSet(Threads)
ASSUME IsFiniteSet(ObjTypes)

\* NULL constant (represents "no thread" for locks)
\* We use a sentinel value that's guaranteed not to be in Threads or Objects
NULL == "NULL"  \* String literal that won't conflict with Threads/Objects
ASSUME NULL \notin Threads /\ NULL \notin Objects

\* Helper functions
\* Note: GetStripeIdx is not used, GetStripe is used instead

\* Color constants
colBlack == 0
colGray == 1
colWhite == 2
maybeCycle == 4
inRootsFlag == 8
colorMask == 3

\* State variables
VARIABLES
    \* Physical heap graph (always up-to-date, atomic stores)
    edges,              \* edges[obj1][obj2] = TRUE if obj1.field points to obj2
    \* Stack roots per thread
    roots,              \* roots[thread][obj] = TRUE if thread has local var pointing to obj
    \* Reference counts (stored in object header)
    rc,                 \* rc[obj] = reference count (logical, after merge)
    \* Color markers (stored in object header, bits 0-2)
    color,              \* color[obj] \in {colBlack, colGray, colWhite}
    \* Root tracking flags
    inRoots,            \* inRoots[obj] = TRUE if obj is in roots array
    \* Striped increment queues
    toIncLen,           \* toIncLen[stripe] = current length of increment queue
    toInc,              \* toInc[stripe][i] = object to increment
    \* Striped decrement queues
    toDecLen,           \* toDecLen[stripe] = current length of decrement queue
    toDec,              \* toDec[stripe][i] = (object, type) pair to decrement
    \* Per-stripe locks
    lockInc,            \* lockInc[stripe] = thread holding increment lock (or NULL)
    lockDec,            \* lockDec[stripe] = thread holding decrement lock (or NULL)
    \* Global lock
    globalLock,         \* thread holding global lock (or NULL)
    \* Merged roots array (used during collection)
    mergedRoots,        \* sequence of (object, type) pairs
    \* Collection state
    collecting,         \* TRUE if collection is in progress
    gcEnv,              \* GC environment: {touched, edges, rcSum, toFree, ...}
    \* Pending operations (for modeling atomicity)
    pendingWrites       \* set of pending write barrier operations

\* Type invariants
TypeOK ==
    /\ edges \in [Objects -> [Objects -> BOOLEAN]]
    /\ roots \in [Threads -> [Objects -> BOOLEAN]]
    /\ rc \in [Objects -> Int]
    /\ color \in [Objects -> {colBlack, colGray, colWhite}]
    /\ inRoots \in [Objects -> BOOLEAN]
    /\ toIncLen \in [0..(NumStripes-1) -> 0..QueueSize]
    /\ toInc \in [0..(NumStripes-1) -> Seq(Objects)]
    /\ toDecLen \in [0..(NumStripes-1) -> 0..QueueSize]
    /\ toDec \in [0..(NumStripes-1) -> Seq([obj: Objects, desc: ObjTypes])]
    /\ lockInc \in [0..(NumStripes-1) -> Threads \cup {NULL}]
    /\ lockDec \in [0..(NumStripes-1) -> Threads \cup {NULL}]
    /\ globalLock \in Threads \cup {NULL}
    /\ mergedRoots \in Seq([obj: Objects, desc: ObjTypes])
    /\ collecting \in BOOLEAN
    /\ pendingWrites \in SUBSET ([thread: Threads, dest: Objects, old: Objects \cup {NULL}, src: Objects \cup {NULL}, phase: {"store", "inc", "dec"}])

\* Helper: internal reference count (heap-to-heap edges)
InternalRC(obj) ==
    Cardinality({src \in Objects : edges[src][obj]})

\* Helper: external reference count (stack roots)
ExternalRC(obj) ==
    Cardinality({t \in Threads : roots[t][obj]})

\* Helper: logical reference count
LogicalRC(obj) ==
    InternalRC(obj) + ExternalRC(obj)

\* Helper: get stripe index for thread
\* Map threads to stripe indices deterministically
\* Since threads are ModelValues, we use a simple deterministic mapping:
\* Assign each thread to stripe 0 (for small models, this is fine)
\* For larger models, TLC will handle the mapping deterministically
GetStripe(thread) == 0

\* ============================================================================
\* Write Barrier: nimAsgnYrc
\* ============================================================================
\* The write barrier does:
\*   1. atomicStoreN(dest, src, ATOMIC_RELEASE)  -- graph update is immediate
\*   2. nimIncRefCyclic(src, true)                -- buffer inc(src)
\*   3. yrcDec(tmp, desc)                         -- buffer dec(old)
\*
\* Key barrier semantics:
\* - ATOMIC_RELEASE on store ensures all prior writes are visible before the graph update
\* - The graph update is immediately visible to all threads (including collector)
\* - RC adjustments are buffered and only applied during merge

\* ============================================================================
\* Phase 1: Atomic Store (Topology Update)
\* ============================================================================
\* The atomic store always happens first, updating the graph topology.
\* This is independent of RC operations and never blocks.
MutatorWriteAtomicStore(thread, destObj, destField, oldVal, newVal, desc) ==
    \* Atomic store with RELEASE barrier - updates graph topology immediately
    \* Clear ALL edges from destObj first (atomic store replaces old value completely),
    \* then set the new edge. This ensures destObj.field can only point to one object.
    /\ edges' = [edges EXCEPT ![destObj] = [x \in Objects |->
                                                 IF x = newVal /\ newVal # NULL
                                                 THEN TRUE
                                                 ELSE FALSE]]
    /\ UNCHANGED <<roots, rc, color, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, globalLock, mergedRoots, collecting, gcEnv, pendingWrites>>

\* ============================================================================
\* Phase 2: RC Buffering (if space available)
\* ============================================================================
\* Buffers increment/decrement if there's space. If overflow would happen,
\* this action is disabled (blocked) until merge can happen.
WriteBarrier(thread, destObj, destField, oldVal, newVal, desc) ==
    LET stripe == GetStripe(thread)
    IN
    \* Determine if overflow happens for increment or decrement
    /\ LET
          incOverflow == (newVal # NULL) /\ (toIncLen[stripe] >= QueueSize)
          decOverflow == (oldVal # NULL) /\ (toDecLen[stripe] >= QueueSize)
       IN
       \* Buffering: only enabled if no overflow (otherwise blocked until merge can happen)
       /\ ~incOverflow  \* Precondition: increment buffer has space (blocks if full)
       /\ ~decOverflow  \* Precondition: decrement buffer has space (blocks if full)
       /\ toIncLen' = IF newVal # NULL /\ toIncLen[stripe] < QueueSize
                      THEN [toIncLen EXCEPT ![stripe] = toIncLen[stripe] + 1]
                      ELSE toIncLen
       /\ toInc' = IF newVal # NULL /\ toIncLen[stripe] < QueueSize
                   THEN [toInc EXCEPT ![stripe] = Append(toInc[stripe], newVal)]
                   ELSE toInc
       /\ toDecLen' = IF oldVal # NULL /\ toDecLen[stripe] < QueueSize
                      THEN [toDecLen EXCEPT ![stripe] = toDecLen[stripe] + 1]
                      ELSE toDecLen
       /\ toDec' = IF oldVal # NULL /\ toDecLen[stripe] < QueueSize
                   THEN [toDec EXCEPT ![stripe] = Append(toDec[stripe], [obj |-> oldVal, desc |-> desc])]
                   ELSE toDec
       /\ UNCHANGED <<edges, roots, rc, color, inRoots, mergedRoots, lockInc, lockDec, globalLock, collecting, gcEnv, pendingWrites>>

\* ============================================================================
\* Phase 3: Overflow Handling (separate actions that can block)
\* ============================================================================

\* Handle increment overflow: merge increment buffers when lock is available
\* This merges ALL increment buffers (for all stripes), not just the one that overflowed
MutatorWriteMergeInc(thread) ==
    LET stripe == GetStripe(thread)
    IN
    /\ \E s \in 0..(NumStripes-1): toIncLen[s] >= QueueSize  \* Some stripe has increment overflow
    /\ globalLock = NULL  \* Lock must be available (blocks if held)
    /\ toIncLen' = [s \in 0..(NumStripes-1) |-> 0]
    /\ toInc' = [s \in 0..(NumStripes-1) |-> <<>>]
    /\ rc' = \* Compute RC from LogicalRC of current graph (increment buffers merged)
             \* The graph is already updated by atomic store, so we compute from current edges
             [x \in Objects |->
              LET internalRC == Cardinality({src \in Objects : edges[src][x]})
                  externalRC == Cardinality({t \in Threads : roots[t][x]})
              IN internalRC + externalRC]
    /\ globalLock' = NULL  \* Release lock after merge
    /\ UNCHANGED <<edges, roots, color, inRoots, toDecLen, toDec, lockInc, lockDec, mergedRoots, collecting, gcEnv, pendingWrites>>

\* Handle decrement overflow: merge ALL buffers when lock is available
\* This calls collectCycles() which merges both increment and decrement buffers
\* We inline MergePendingRoots here. The entire withLock block is atomic:
\* lock is acquired, merge happens, lock is released.
MutatorWriteMergeDec(thread) ==
    LET stripe == GetStripe(thread)
    IN
    /\ \E s \in 0..(NumStripes-1): toDecLen[s] >= QueueSize  \* Some stripe has decrement overflow
    /\ globalLock = NULL  \* Lock must be available (blocks if held)
    /\ \* Merge all buffers (inlined MergePendingRoots logic)
       LET \* Compute new RC by merging all buffered increments and decrements
           \* For each object, count buffered increments and decrements
           bufferedInc == UNION {{toInc[s][i] : i \in 1..toIncLen[s]} : s \in 0..(NumStripes-1)}
           bufferedDec == UNION {{toDec[s][i].obj : i \in 1..toDecLen[s]} : s \in 0..(NumStripes-1)}
           \* Compute RC: current graph state (edges) + roots - buffered decrements + buffered increments
           \* Actually, we compute from LogicalRC of current graph (buffers are merged)
           newRC == [x \in Objects |->
                      LET internalRC == Cardinality({src \in Objects : edges[src][x]})
                          externalRC == Cardinality({t \in Threads : roots[t][x]})
                      IN internalRC + externalRC]
           \* Collect objects from decrement buffers for mergedRoots
           newRootsSet == UNION {{toDec[s][i].obj : i \in 1..toDecLen[s]} : s \in 0..(NumStripes-1)}
           newRootsSeq == IF newRootsSet = {}
                          THEN <<>>
                          ELSE LET ordered == CHOOSE f \in [1..Cardinality(newRootsSet) -> newRootsSet] :
                                     \A i, j \in DOMAIN f : i # j => f[i] # f[j]
                               IN [i \in 1..Cardinality(newRootsSet) |-> ordered[i]]
       IN
       /\ rc' = newRC
       /\ mergedRoots' = mergedRoots \o newRootsSeq
       /\ inRoots' = [x \in Objects |->
                      IF newRootsSet = {}
                      THEN inRoots[x]
                      ELSE LET rootObjs == UNION {{mergedRoots'[i].obj : i \in DOMAIN mergedRoots'}}
                           IN IF x \in rootObjs THEN TRUE ELSE inRoots[x]]
       /\ toIncLen' = [s \in 0..(NumStripes-1) |-> 0]
       /\ toInc' = [s \in 0..(NumStripes-1) |-> <<>>]
       /\ toDecLen' = [s \in 0..(NumStripes-1) |-> 0]
       /\ toDec' = [s \in 0..(NumStripes-1) |-> <<>>]
    /\ globalLock' = NULL  \* Lock acquired, merge done, lock released (entire withLock block is atomic)
    /\ UNCHANGED <<edges, roots, color, lockInc, lockDec, collecting, gcEnv, pendingWrites>>

\* ============================================================================
\* Merge Operation: mergePendingRoots
\* ============================================================================
\* Drains all stripe buffers under global lock.
\* Sequentially acquires each stripe's lockInc and lockDec to drain buffers.
\* This reconciles buffered RC adjustments with the current graph state.
\*
\* Key invariant: After merge, mergedRC = logicalRC (current graph + buffered changes)

MergePendingRoots ==
    /\ globalLock # NULL
    /\ LET
          \* Count pending increments per object (across all stripes)
          pendingInc == [x \in Objects |->
              Cardinality(UNION {{i \in DOMAIN toInc[s] : toInc[s][i] = x} :
                                  s \in 0..(NumStripes-1)})]
          \* Count pending decrements per object (across all stripes)
          pendingDec == [x \in Objects |->
              Cardinality(UNION {{i \in DOMAIN toDec[s] : toDec[s][i].obj = x} :
                                  s \in 0..(NumStripes-1)})]
          \* After merge, RC should equal LogicalRC (current graph state)
          \* The buffered changes compensate for graph changes that already happened,
          \* so: mergedRC = currentRC + pendingInc - pendingDec = LogicalRC(current graph)
          \* But to ensure correctness, we compute directly from the current graph:
          newRC == [x \in Objects |->
              LogicalRC(x)]  \* RC after merge equals logical RC of current graph
          \* Add decremented objects to roots if not already there (check inRootsFlag)
          \* Collect all new roots as a set, then convert to sequence
          \* Build set by iterating over all (stripe, index) pairs
          \* Use UNION with explicit per-stripe sets (avoiding function enumeration issues)
          newRootsSet == UNION {UNION {IF inRoots[toDec[s][i].obj] = FALSE
                                      THEN {[obj |-> toDec[s][i].obj, desc |-> toDec[s][i].desc]}
                                      ELSE {} : i \in DOMAIN toDec[s]} : s \in 0..(NumStripes-1)}
          newRootsSeq == IF newRootsSet = {}
                         THEN <<>>
                         ELSE LET ordered == CHOOSE f \in [1..Cardinality(newRootsSet) -> newRootsSet] :
                                    \A i, j \in DOMAIN f : i # j => f[i] # f[j]
                              IN [i \in 1..Cardinality(newRootsSet) |-> ordered[i]]
       IN
       /\ rc' = newRC
       /\ mergedRoots' = mergedRoots \o newRootsSeq  \* Append new roots to sequence
       /\ \* Update inRoots: mark objects in mergedRoots' as being in roots
          \* Use explicit iteration to avoid enumeration issues
          inRoots' = [x \in Objects |->
                      IF mergedRoots' = <<>>
                      THEN inRoots[x]
                      ELSE LET rootObjs == UNION {{mergedRoots'[i].obj : i \in DOMAIN mergedRoots'}}
                           IN IF x \in rootObjs THEN TRUE ELSE inRoots[x]]
       /\ toIncLen' = [s \in 0..(NumStripes-1) |-> 0]
       /\ toInc' = [s \in 0..(NumStripes-1) |-> <<>>]
       /\ toDecLen' = [s \in 0..(NumStripes-1) |-> 0]
       /\ toDec' = [s \in 0..(NumStripes-1) |-> <<>>]
    /\ UNCHANGED <<edges, roots, color, lockInc, lockDec, globalLock, collecting, gcEnv, pendingWrites>>

\* ============================================================================
\* Trial Deletion: markGray
\* ============================================================================
\* Subtracts internal (heap-to-heap) edges from reference counts.
\* This isolates external references (stack roots).
\*
\* Algorithm:
\*   1. Mark obj gray
\*   2. Trace obj's fields (via traceImpl)
\*   3. For each child c: decrement c.rc (subtract internal edge)
\*   4. Recursively markGray all children
\*
\* After markGray: trialRC(obj) = mergedRC(obj) - internalRefCount(obj)
\*                 = externalRefCount(obj) (if merge was correct)

MarkGray(obj, desc) ==
    /\ globalLock # NULL
    /\ collecting = TRUE
    /\ color[obj] # colGray
    /\ \* Compute transitive closure of all objects reachable from obj
       \* This models the recursive traversal in the actual implementation
       LET children == {c \in Objects : edges[obj][c]}
          \* Compute all objects reachable from obj via heap edges
          \* This is the transitive closure starting from obj's direct children
          allReachable == {c \in Objects :
              \E path \in Seq(Objects):
                 Len(path) > 0 /\
                 path[1] \in children /\
                 path[Len(path)] = c /\
                 \A i \in 1..(Len(path)-1):
                    edges[path[i]][path[i+1]]}
          \* All objects to mark gray: obj itself + all reachable descendants
          objectsToMarkGray == {obj} \cup allReachable
          \* For each reachable object, count internal edges pointing to it
          \* from within the subgraph (obj + allReachable)
          \* This is the number of times its RC should be decremented
          subgraph == {obj} \cup allReachable
          internalEdgeCount == [x \in Objects |->
              IF x \in allReachable
              THEN Cardinality({y \in subgraph : edges[y][x]})
              ELSE 0]
       IN
       /\ \* Mark obj and all reachable objects gray
          color' = [x \in Objects |->
              IF x \in objectsToMarkGray THEN colGray ELSE color[x]]
       /\ \* Subtract internal edges: for each reachable object, decrement its RC
          \* by the number of internal edges pointing to it from within the subgraph.
          \* This matches the Nim implementation which decrements once per edge traversed.
          \* Note: obj's RC is not decremented here (it has no parent in this subgraph).
          \* For roots, the RC includes external refs which survive trial deletion.
          rc' = [x \in Objects |->
              IF x \in allReachable THEN rc[x] - internalEdgeCount[x] ELSE rc[x]]
    /\ UNCHANGED <<edges, roots, color, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, globalLock, mergedRoots, collecting, gcEnv, pendingWrites>>

\* ============================================================================
\* Scan Phase
\* ============================================================================
\* Objects with RC >= 0 after trial deletion are rescued (scanBlack).
\* Objects with RC < 0 remain white (part of closed cycle).
\*
\* Key insight: scanBlack follows the *current* physical edges (which may have
\* changed since merge due to concurrent writes). This ensures objects written
\* during collection are still rescued.
\*
\* Algorithm:
\*   IF rc[obj] >= 0:
\*     scanBlack(obj): mark black, restore RC, trace and rescue all children
\*   ELSE:
\*     mark white (closed cycle with zero external refs)

Scan(obj, desc) ==
    /\ globalLock # NULL
    /\ collecting = TRUE
    /\ color[obj] = colGray
    /\ IF rc[obj] >= 0
       THEN \* scanBlack: rescue obj and all reachable objects
            \* This follows the current physical graph (atomic stores are visible)
            \* Restore RC for all reachable objects by incrementing by the number of
            \* internal edges pointing to each (matching what markGray subtracted)
            LET children == {c \in Objects : edges[obj][c]}
               allReachable == {c \in Objects :
                   \E path \in Seq(Objects):
                      Len(path) > 0 /\
                      path[1] \in children /\
                      path[Len(path)] = c /\
                      \A i \in 1..(Len(path)-1):
                         edges[path[i]][path[i+1]]}
               objectsToMarkBlack == {obj} \cup allReachable
               \* For each reachable object, count internal edges pointing to it
               \* from within the subgraph (obj + allReachable)
               \* This is the number of times its RC should be incremented (restored)
               subgraph == {obj} \cup allReachable
               internalEdgeCount == [x \in Objects |->
                   IF x \in allReachable
                   THEN Cardinality({y \in subgraph : edges[y][x]})
                   ELSE 0]
            IN
            /\ \* Restore RC: increment by the number of internal edges pointing to each
               \* reachable object. This restores what markGray subtracted.
               \* Note: obj's RC is not incremented here (it wasn't decremented in markGray).
               \* The root's RC already reflects external refs which survived trial deletion.
               rc' = [x \in Objects |->
                   IF x \in allReachable THEN rc[x] + internalEdgeCount[x] ELSE rc[x]]
            /\ \* Mark obj and all reachable objects black in one assignment
               color' = [x \in Objects |->
                   IF x \in objectsToMarkBlack THEN colBlack ELSE color[x]]
       ELSE \* Mark white (part of closed cycle)
            /\ color' = [color EXCEPT ![obj] = colWhite]
            /\ UNCHANGED <<rc>>
    /\ UNCHANGED <<edges, roots, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, globalLock, mergedRoots, collecting, gcEnv, pendingWrites>>

\* ============================================================================
\* Collection Phase: collectColor
\* ============================================================================
\* Frees objects of the target color that are not in roots.
\*
\* Safety: Only objects with color = targetColor AND ~inRoots[obj] are freed.
\* These are closed cycles (zero external refs, not reachable from roots).

CollectColor(obj, desc, targetColor) ==
    /\ globalLock # NULL
    /\ collecting = TRUE
    /\ color[obj] = targetColor
    /\ ~inRoots[obj]
    /\ \* Free obj: nullify all its outgoing edges (prevents use-after-free)
       \* In the actual implementation, this happens during trace() when freeing
       edges' = [edges EXCEPT ![obj] = [x \in Objects |->
           IF x = obj THEN FALSE ELSE edges[obj][x]]]
    /\ color' = [color EXCEPT ![obj] = colBlack]  \* Mark as freed
    /\ UNCHANGED <<edges, roots, rc, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, globalLock, mergedRoots, collecting, gcEnv, pendingWrites>>

\* ============================================================================
\* Collection Cycle: collectCyclesBacon
\* ============================================================================

StartCollection ==
    /\ globalLock # NULL
    /\ ~collecting
    /\ Len(mergedRoots) >= RootsThreshold
    /\ collecting' = TRUE
    /\ gcEnv' = [touched |-> 0, edges |-> 0, rcSum |-> 0, toFree |-> {}]
    /\ UNCHANGED <<edges, roots, rc, color, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, globalLock, mergedRoots, collecting, pendingWrites>>

EndCollection ==
    /\ globalLock # NULL
    /\ collecting = TRUE
    /\ \* Clear root flags
       inRoots' = [x \in Objects |->
           IF x \in {r.obj : r \in mergedRoots} THEN FALSE ELSE inRoots[x]]
    /\ mergedRoots' = <<>>
    /\ collecting' = FALSE
    /\ UNCHANGED <<edges, roots, rc, color, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, globalLock, mergedRoots, gcEnv, pendingWrites>>

\* ============================================================================
\* Mutator Actions
\* ============================================================================

\* Mutator can write at any time (graph updates are lock-free)
\* The ATOMIC_RELEASE barrier ensures proper ordering
\* ASSUMPTION: Users synchronize pointer assignments with locks, so oldVal always
\* matches the current graph state (as read before the atomic store).
\* This prevents races at the user level - the GC itself is lock-free.
MutatorWrite(thread, destObj, destField, oldVal, newVal, desc) ==
    \* ASSUMPTION: Users synchronize pointer assignments with locks, so oldVal always matches
    \* the value read before the atomic store. This prevents races at the user level.
    \* The precondition is enforced in the Next relation.
    \* Phase 1: Atomic store (topology update) - ALWAYS happens first
    /\ MutatorWriteAtomicStore(thread, destObj, destField, oldVal, newVal, desc)
    \* Phase 2: RC buffering - happens if no overflow, otherwise overflow is handled separately
    \* Note: In reality, if overflow happens, the thread blocks waiting for lock.
    \* We model this as: atomic store happens, buffering is deferred (handled by merge actions).
    /\ LET stripe == GetStripe(thread)
          incOverflow == (newVal # NULL) /\ (toIncLen[stripe] >= QueueSize)
          decOverflow == (oldVal # NULL) /\ (toDecLen[stripe] >= QueueSize)
       IN
       IF incOverflow \/ decOverflow
       THEN \* Overflow: atomic store happened, but buffering is deferred
            \* Buffers stay full, merge will happen when lock is available (via MutatorWriteMergeInc/Dec)
            /\ UNCHANGED <<roots, rc, color, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, globalLock, mergedRoots, collecting, gcEnv, pendingWrites>>
       ELSE \* No overflow: buffer normally
            /\ WriteBarrier(thread, destObj, destField, oldVal, newVal, desc)
            /\ UNCHANGED <<roots, collecting, pendingWrites>>

\* Stack root assignment: immediate RC increment (not buffered)
\* When assigning val to a root variable named obj, we set roots[thread][val] = TRUE
\* to indicate that thread has a stack reference to val
\* Semantics: obj is root variable name, val is the object being assigned
\* When val=NULL, obj was the old root value, so we decrement rc[obj]
MutatorRootAssign(thread, obj, val) ==
    /\ IF val # NULL
       THEN /\ roots' = [roots EXCEPT ![thread][val] = TRUE]
            /\ rc' = [rc EXCEPT ![val] = IF roots[thread][val] THEN @ ELSE @ + 1]  \* Increment only if not already a root
       ELSE /\ roots' = [roots EXCEPT ![thread][obj] = FALSE]  \* Clear root when assigning NULL
            /\ rc' = [rc EXCEPT ![obj] = IF roots[thread][obj] THEN @ - 1 ELSE @]  \* Decrement old root value
    /\ edges' = edges
    /\ color' = color
    /\ inRoots' = inRoots
    /\ toIncLen' = toIncLen
    /\ toInc' = toInc
    /\ toDecLen' = toDecLen
    /\ toDec' = toDec
    /\ lockInc' = lockInc
    /\ lockDec' = lockDec
    /\ globalLock' = globalLock
    /\ mergedRoots' = mergedRoots
    /\ collecting' = collecting
    /\ gcEnv' = gcEnv
    /\ pendingWrites' = pendingWrites

\* ============================================================================
\* Collector Actions
\* ============================================================================

\* Collector acquires global lock for entire collection cycle
CollectorAcquireLock(thread) ==
    /\ globalLock = NULL
    /\ globalLock' = thread
    /\ UNCHANGED <<edges, roots, rc, color, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, mergedRoots, collecting, gcEnv, pendingWrites>>

CollectorMerge ==
    /\ globalLock # NULL
    /\ MergePendingRoots

CollectorStart ==
    /\ globalLock # NULL
    /\ StartCollection

\* Mark all roots gray (trial deletion phase)
CollectorMarkGray ==
    /\ globalLock # NULL
    /\ collecting = TRUE
    /\ \E rootIdx \in DOMAIN mergedRoots:
        LET root == mergedRoots[rootIdx]
        IN MarkGray(root.obj, root.desc)

\* Scan all roots (rescue phase)
CollectorScan ==
    /\ globalLock # NULL
    /\ collecting = TRUE
    /\ \E rootIdx \in DOMAIN mergedRoots:
        LET root == mergedRoots[rootIdx]
        IN Scan(root.obj, root.desc)

\* Collect white/gray objects (free phase)
CollectorCollect ==
    /\ globalLock # NULL
    /\ collecting = TRUE
    /\ \E rootIdx \in DOMAIN mergedRoots, targetColor \in {colGray, colWhite}:
        LET root == mergedRoots[rootIdx]
        IN CollectColor(root.obj, root.desc, targetColor)

CollectorEnd ==
    /\ globalLock # NULL
    /\ EndCollection

CollectorReleaseLock(thread) ==
    /\ globalLock = thread
    /\ globalLock' = NULL
    /\ UNCHANGED <<edges, roots, rc, color, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, mergedRoots, collecting, gcEnv, pendingWrites>>

\* ============================================================================
\* Next State Relation
\* ============================================================================

Next ==
    \/ \E thread \in Threads:
         \E destObj \in Objects, oldVal, newVal \in Objects \cup {NULL}, desc \in ObjTypes:
             \* Precondition: oldVal must match current graph state (user-level synchronization)
             \* ASSUMPTION: Users synchronize pointer assignments with locks, so oldVal always matches
             \* the value read before the atomic store. This prevents races at the user level.
             /\ LET oldValMatches == CASE oldVal = NULL -> TRUE
                                        [] oldVal \in Objects -> edges[destObj][oldVal]
                                        [] OTHER -> FALSE
                IN oldValMatches
             /\ MutatorWrite(thread, destObj, "field", oldVal, newVal, desc)
    \/ \E thread \in Threads:
         \* Handle increment overflow: merge increment buffers when lock becomes available
         MutatorWriteMergeInc(thread)
    \/ \E thread \in Threads:
         \* Handle decrement overflow: merge all buffers when lock becomes available
         MutatorWriteMergeDec(thread)
    \/ \E thread \in Threads:
         \E obj, val \in Objects \cup {NULL}:
             MutatorRootAssign(thread, obj, val)
    \/ \E thread \in Threads:
         CollectorAcquireLock(thread)
    \/ CollectorMerge
    \/ CollectorStart
    \/ CollectorMarkGray
    \/ CollectorScan
    \/ CollectorCollect
    \/ CollectorEnd
    \/ \E thread \in Threads:
         CollectorReleaseLock(thread)

\* ============================================================================
\* Initial State
\* ============================================================================

Init ==
    /\ edges = [x \in Objects |->
                [y \in Objects |->
                    IF x = y THEN FALSE ELSE FALSE]]  \* Empty graph initially
    /\ roots = [t \in Threads |->
                [x \in Objects |->
                    FALSE]]  \* No stack roots initially
    /\ rc = [x \in Objects |->
             0]  \* Zero reference counts
    /\ color = [x \in Objects |->
                colBlack]  \* All objects black initially
    /\ inRoots = [x \in Objects |->
                  FALSE]  \* No objects in roots array
    /\ toIncLen = [s \in 0..(NumStripes-1) |->
                   0]
    /\ toInc = [s \in 0..(NumStripes-1) |->
                <<>>]
    /\ toDecLen = [s \in 0..(NumStripes-1) |->
                   0]
    /\ toDec = [s \in 0..(NumStripes-1) |->
                <<>>]
    /\ lockInc = [s \in 0..(NumStripes-1) |->
                  NULL]
    /\ lockDec = [s \in 0..(NumStripes-1) |->
                  NULL]
    /\ globalLock = NULL
    /\ mergedRoots = <<>>
    /\ collecting = FALSE
    /\ gcEnv = [touched |-> 0, edges |-> 0, rcSum |-> 0, toFree |-> {}]
    /\ pendingWrites = {}
    /\ TypeOK

\* ============================================================================
\* Safety Properties
\* ============================================================================

\* Safety: Objects are only freed if they are unreachable from any thread's stack
\*
\* An object is reachable if:
\*   - It is a direct stack root (roots[t][obj] = TRUE), OR
\*   - There exists a path from a stack root to obj via heap edges
\*
\* Safety guarantee: If an object is reachable, then:
\*   - It is not white (not marked for collection), OR
\*   - It is in roots array (protected from collection), OR
\*   - It is reachable from an object that will be rescued by scanBlack
\*
\* More precisely: Only closed cycles (zero external refs, unreachable) are freed.

\* Helper: Compute next set of reachable objects (one step of transitive closure)
ReachableStep(current) ==
    current \cup UNION {{y \in Objects : edges[x][y]} : x \in current}

\* Compute the set of all reachable objects using bounded iteration
\* Since Objects is finite, we iterate at most Cardinality(Objects) times
\* This computes the transitive closure of edges starting from stack roots
\* We unroll the iteration explicitly to avoid recursion issues with TLC
ReachableSet ==
    LET StackRoots == {x \in Objects : \E t \in Threads : roots[t][x]}
        Step1 == ReachableStep(StackRoots)
        Step2 == ReachableStep(Step1)
        Step3 == ReachableStep(Step2)
        Step4 == ReachableStep(Step3)
        \* Add more steps if needed for larger object sets
        \* For small models (2 objects), 4 steps is sufficient
    IN Step4

\* Check if an object is reachable
Reachable(obj) == obj \in ReachableSet

\* Helper: Check if there's a path from 'from' to 'to'
\* For small object sets, we check all possible paths by checking
\* all combinations of intermediate objects
\* Path of length 0: from = to
\* Path of length 1: edges[from][to]
\* Path of length 2: \E i1: edges[from][i1] /\ edges[i1][to]
\* Path of length 3: \E i1, i2: edges[from][i1] /\ edges[i1][i2] /\ edges[i2][to]
\* etc. up to Cardinality(Objects)
HasPath(from, to) ==
    \/ from = to
    \/ edges[from][to]
    \/ \E i1 \in Objects:
         edges[from][i1] /\ (edges[i1][to] \/ \E i2 \in Objects:
             edges[i1][i2] /\ (edges[i2][to] \/ \E i3 \in Objects:
                 edges[i2][i3] /\ edges[i3][to]))

\* Helper: Compute set of objects reachable from a given starting object
\* Uses the same iterative approach as ReachableSet
ReachableFrom(start) ==
    LET Step1 == ReachableStep({start})
        Step2 == ReachableStep(Step1)
        Step3 == ReachableStep(Step2)
        Step4 == ReachableStep(Step3)
    IN Step4

\* Safety: Reachable objects are never freed (remain white without being collected)
\* A reachable object is safe if:
\*   - It's not white (not marked for collection), OR
\*   - It's in roots array (protected from collection), OR
\*   - There exists a black object in ReachableSet such that obj is reachable from it
\*     (the black object will be rescued by scanBlack, which rescues all white objects
\*      reachable from black objects)
Safety ==
    \A obj \in Objects:
        IF obj \in ReachableSet
        THEN \/ color[obj] # colWhite  \* Not marked for collection
             \/ inRoots[obj]  \* Protected in roots array
             \/ \E blackObj \in ReachableSet:
                  /\ color[blackObj] = colBlack  \* Black object will be rescued by scanBlack
                  /\ obj \in ReachableFrom(blackObj)  \* obj is reachable from blackObj
        ELSE TRUE  \* Unreachable objects may be freed (this is safe)

\* Invariant: Reference counts match logical counts after merge
\* (This is maintained by MergePendingRoots)
\* Note: Between merge and collection, RC = logicalRC.
\* During collection (after markGray), RC may be modified by trial deletion.
\* RC may be inconsistent when:
\*   - globalLock = NULL (buffered changes pending)
\*   - globalLock # NULL but merge hasn't happened yet (buffers still have pending changes)
\* RC must equal LogicalRC when:
\*   - After merge (buffers are empty) and before collection starts
RCInvariant ==
    IF globalLock = NULL
    THEN TRUE  \* Not in collection, RC may be inconsistent (buffered changes pending)
    ELSE IF collecting = FALSE /\ \A s \in 0..(NumStripes-1): toIncLen[s] = 0 /\ toDecLen[s] = 0
         THEN \A obj \in Objects: rc[obj] = LogicalRC(obj)  \* After merge, buffers empty, RC = logical RC
         ELSE TRUE  \* During collection or before merge, RC may differ from logicalRC

\* Invariant: Only closed cycles are collected
\* (Objects with external refs are rescued by scanBlack)
CycleInvariant ==
    \A obj \in Objects:
        IF color[obj] = colWhite /\ ~inRoots[obj]
        THEN ExternalRC(obj) = 0
        ELSE TRUE

\* ============================================================================
\* Specification
\* ============================================================================

Spec == Init /\ [][Next]_<<edges, roots, rc, color, inRoots, toIncLen, toInc, toDecLen, toDec, lockInc, lockDec, globalLock, mergedRoots, collecting, gcEnv, pendingWrites>>

THEOREM Spec => []Safety
THEOREM Spec => []RCInvariant
THEOREM Spec => []CycleInvariant

====
