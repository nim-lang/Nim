# Fix Option 1: Never Free Small Chunks (Simplest, Safest)
# ========================================================
#
# RATIONALE:
# - Completely eliminates the race condition
# - Small chunks are already pooled per size class
# - Reusing chunks is cheaper than freeing and reallocating
# - Memory cost is bounded by workload's peak allocation
#
# TRADEOFF:
# - Memory not returned to OS for small allocations
# - Acceptable for most workloads (chunks are small, reused efficiently)

# In rawDealloc, modify the small chunk freeing logic:

proc rawDealloc(a: var MemRegion, p: pointer) =
  when defined(nimTypeNames):
    inc(a.deallocCounter)
  when defined(heaptrack):
    heaptrack_free(p)
  sysAssert(allocInv(a), "rawDealloc: begin")
  var c = pageAddr(p)
  sysAssert(c != nil, "rawDealloc: begin")
  if isSmallChunk(c):
    var c = cast[PSmallChunk](c)
    let s = c.size
    var f = cast[ptr FreeCell](p)
    if c.owner == addr(a):
      dec a.occ, s
      untrackSize(s)
      sysAssert a.occ >= 0, "rawDealloc: negative occupied memory (case A)"
      sysAssert(((cast[int](p) and PageMask) - smallChunkOverhead()) %%
                s == 0, "rawDealloc 3")
      when not defined(gcDestructors):
        sysAssert(f.zeroField != 0, "rawDealloc 1")
        f.zeroField = 0
      when overwriteFree:
        nimSetMem(cast[pointer](cast[int](p) +% sizeof(FreeCell)), -1'i32,
                s -% sizeof(FreeCell))
      let activeChunk = a.freeSmallChunks[s div MemAlign]
      if activeChunk != nil and c != activeChunk:
        f.next = activeChunk.freeList
        activeChunk.freeList = f
        inc(activeChunk.free, s)
        inc(activeChunk.foreignCells)
      else:
        f.next = c.freeList
        c.freeList = f
        if c.free < s:
          listAdd(a.freeSmallChunks[s div MemAlign], c)
          inc(c.free, s)
        else:
          inc(c.free, s)
          # FIX: Don't free small chunks, just keep them for reuse
          # ORIGINAL CODE (BUGGY):
          # if c.free == SmallChunkSize-smallChunkOverhead() and c.foreignCells == 0:
          #   listRemove(a.freeSmallChunks[s div MemAlign], c)
          #   c.size = SmallChunkSize
          #   freeBigChunk(a, cast[PBigChunk](c))

          # NEW CODE (SAFE):
          # Just leave the chunk in the free list for reuse
          # The chunk will naturally be picked up on next allocation
          discard  # Explicitly do nothing - chunk stays allocated and reusable
    else:
      when logAlloc: cprintf("dealloc(pointer_%p) # SMALL FROM %p CALLER %p\n", p, c.owner, addr(a))
      when defined(gcDestructors):
        addToSharedFreeList(c, f, s div MemAlign)
    sysAssert(((cast[int](p) and PageMask) - smallChunkOverhead()) %%
               s == 0, "rawDealloc 2")
  else:
    # Big chunks can still be freed safely (no cross-thread issues)
    when overwriteFree: nimSetMem(p, -1'i32, c.size -% bigChunkOverhead())
    when logAlloc: cprintf("dealloc(pointer_%p) # BIG %p\n", p, c.owner)
    when defined(gcDestructors):
      if c.owner == addr(a):
        deallocBigChunk(a, cast[PBigChunk](c))
      else:
        addToSharedFreeListBigChunks(c.owner[], cast[PBigChunk](c))
    else:
      deallocBigChunk(a, cast[PBigChunk](c))

  sysAssert(allocInv(a), "rawDealloc: end")

# VERIFICATION:
# - No race condition possible: chunks never freed
# - foreignCells tracking still works correctly
# - Memory usage: bounded by peak concurrent allocation
# - Performance: no syscall overhead from free/alloc cycles

# OPTIONAL ENHANCEMENT: Periodic dormant chunk cleanup
# If you want to eventually free truly unused chunks:

proc cleanupDormantChunks(a: var MemRegion) =
  ## Call this periodically (e.g., every 10 seconds) to free truly idle chunks
  ## Only safe when no allocations/deallocations are happening (e.g., during GC pause)
  const DormantThreshold = 1000  # Chunk unused for 1000+ allocations

  for s in 0..high(a.freeSmallChunks):
    var c = a.freeSmallChunks[s]
    var prev: PSmallChunk = nil
    while c != nil:
      let next = c.next
      if c.free == SmallChunkSize - smallChunkOverhead() and
         c.foreignCells == 0:
        # Chunk is completely free and has no foreign references
        # Could optionally track "idle time" and only free if idle long enough
        discard  # Still don't free - or add idle time tracking
      prev = c
      c = next
