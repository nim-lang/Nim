-------------------------- MODULE alloc --------------------------
(*
TLA+ specification of Nim's multi-threaded allocator (alloc.nim)
Focus: Small chunk allocation with shared free lists and foreign cells

Key mechanisms modeled:
- Per-thread MemRegion with freeSmallChunks array
- Shared free lists for cross-thread deallocation
- Foreign cells tracking to prevent premature chunk deallocation
- Active chunk management
*)

EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS
    Threads,        (* Set of thread IDs *)
    MaxChunks,      (* Maximum number of chunks per thread *)
    SizeClass,      (* Single size class to model (simplified) *)
    MaxCells        (* Maximum cells per chunk *)

ASSUME MaxChunks > 0
ASSUME MaxCells > 0

(*--algorithm alloc

variables
    (* Per-thread state *)
    freeSmallChunks = [t \in Threads |-> NULL],  (* Active chunk for each thread *)
    sharedFreeLists = [t \in Threads |-> <<>>],  (* Atomic queue of free cells *)

    (* Chunk state - owner is the creating thread *)
    chunkOwner = [c \in 1..MaxChunks |-> NULL],
    chunkFree = [c \in 1..MaxChunks |-> 0],       (* Free capacity in bytes *)
    chunkForeignCells = [c \in 1..MaxChunks |-> 0], (* Count of foreign cells *)
    chunkFreeList = [c \in 1..MaxChunks |-> <<>>],  (* List of free cell IDs *)
    chunkAcc = [c \in 1..MaxChunks |-> 0],          (* Accumulator offset *)
    chunkInList = [c \in 1..MaxChunks |-> FALSE],   (* Is chunk in freeSmallChunks? *)

    (* Cell tracking *)
    cellOwner = [cell \in 1..MaxCells |-> NULL],    (* Which chunk owns this cell *)
    cellAllocated = [cell \in 1..MaxCells |-> FALSE], (* Is cell currently allocated *)

    nextChunk = 1,   (* Next chunk ID to allocate *)
    nextCell = 1;    (* Next cell ID to use *)

define
    NULL == 0
    ChunkSize == MaxCells  (* Simplified: each chunk holds MaxCells cells *)
    CellSize == 1          (* Simplified: each cell is 1 unit *)

    (* Invariants *)

    (* A chunk cannot be freed if it has foreign cells *)
    NoLeakInvariant ==
        \A c \in 1..MaxChunks:
            (chunkOwner[c] = NULL) => (chunkForeignCells[c] = 0)

    (* Foreign cells must be tracked correctly *)
    ForeignCellsAccurate ==
        \A c \in 1..MaxChunks:
            chunkOwner[c] # NULL =>
                chunkForeignCells[c] =
                    Cardinality({cell \in 1..MaxCells :
                        cell \in DOMAIN cellOwner /\
                        cellOwner[cell] # NULL /\
                        cellOwner[cell] # c /\
                        cell \in SeqToSet(chunkFreeList[c])})

    (* A cell cannot be in multiple free lists *)
    UniqueFreeListMembership ==
        \A cell \in 1..MaxCells:
            Cardinality({c \in 1..MaxChunks : cell \in SeqToSet(chunkFreeList[c])}) +
            Cardinality({t \in Threads : cell \in SeqToSet(sharedFreeLists[t])}) <= 1

    (* Allocated cells should not be in any free list *)
    NoAllocatedInFreeList ==
        \A cell \in 1..MaxCells:
            cellAllocated[cell] =>
                /\ \A c \in 1..MaxChunks: cell \notin SeqToSet(chunkFreeList[c])
                /\ \A t \in Threads: cell \notin SeqToSet(sharedFreeLists[t])

    (* Helper to convert sequence to set *)
    SeqToSet(seq) == {seq[i] : i \in DOMAIN seq}

    TypeOK ==
        /\ nextChunk \in 1..(MaxChunks+1)
        /\ nextCell \in 1..(MaxCells+1)
        /\ \A t \in Threads: freeSmallChunks[t] \in 0..MaxChunks
end define;

(* Macro for atomic prepend to shared free list *)
macro atomicPrepend(list, elem) begin
    list := <<elem>> \o list;
end macro;

(*
 * Thread allocates a cell of the given size
 * Corresponds to rawAlloc() for small chunks
 *)
procedure Alloc(thread, size)
variables
    activeChunk = 0,
    newChunk = 0,
    cell = 0,
    sharedCells = <<>>;
begin
    AllocStart:
        activeChunk := freeSmallChunks[thread];

    CheckActiveChunk:
        if activeChunk = NULL then
            (* No active chunk, need to get a new one *)
            goto GetNewChunk;
        end if;

    CheckFreeList:
        if Len(chunkFreeList[activeChunk]) > 0 then
            (* Free cells available, take one *)
            cell := Head(chunkFreeList[activeChunk]);
            chunkFreeList[activeChunk] := Tail(chunkFreeList[activeChunk]);

            (* Check if this is a foreign cell *)
            if cellOwner[cell] # activeChunk then
                chunkForeignCells[activeChunk] := chunkForeignCells[activeChunk] - 1;
            end if;

            chunkFree[activeChunk] := chunkFree[activeChunk] - size;
            cellAllocated[cell] := TRUE;

            goto FetchShared;
        end if;

    CheckAccumulator:
        if chunkAcc[activeChunk] + size <= ChunkSize then
            (* Use accumulator *)
            assert nextCell <= MaxCells;
            cell := nextCell;
            nextCell := nextCell + 1;
            cellOwner[cell] := activeChunk;
            cellAllocated[cell] := TRUE;

            chunkAcc[activeChunk] := chunkAcc[activeChunk] + size;
            chunkFree[activeChunk] := chunkFree[activeChunk] - size;

            goto FetchShared;
        end if;

    GetNewChunk:
        (* Allocate a new chunk *)
        if nextChunk <= MaxChunks then
            newChunk := nextChunk;
            nextChunk := nextChunk + 1;

            chunkOwner[newChunk] := thread;
            chunkFree[newChunk] := ChunkSize - size;
            chunkAcc[newChunk] := size;
            chunkForeignCells[newChunk] := 0;
            chunkFreeList[newChunk] := <<>>;
            chunkInList[newChunk] := TRUE;

            freeSmallChunks[thread] := newChunk;

            (* Allocate first cell *)
            assert nextCell <= MaxCells;
            cell := nextCell;
            nextCell := nextCell + 1;
            cellOwner[cell] := newChunk;
            cellAllocated[cell] := TRUE;

            activeChunk := newChunk;
            goto FetchShared;
        else
            (* Out of chunks *)
            goto AllocDone;
        end if;

    FetchShared:
        (* Fetch deferred cells from shared list (compensateCounters logic) *)
        if activeChunk # NULL /\ Len(chunkFreeList[activeChunk]) = 0 then
            sharedCells := sharedFreeLists[thread];
            sharedFreeLists[thread] := <<>>;

            (* Process shared cells *)
            while Len(sharedCells) > 0 do
                cell := Head(sharedCells);
                sharedCells := Tail(sharedCells);

                chunkFreeList[activeChunk] := Append(chunkFreeList[activeChunk], cell);
                chunkFree[activeChunk] := chunkFree[activeChunk] + size;

                (* Track as foreign if from different chunk *)
                if cellOwner[cell] # activeChunk then
                    chunkForeignCells[activeChunk] := chunkForeignCells[activeChunk] + 1;
                end if;
            end while;
        end if;

    CheckRemoveFromList:
        if activeChunk # NULL /\ chunkFree[activeChunk] < size then
            (* Chunk exhausted, remove from active list *)
            freeSmallChunks[thread] := NULL;
            chunkInList[activeChunk] := FALSE;
        end if;

    AllocDone:
        return;
end procedure;

(*
 * Thread deallocates a cell
 * Corresponds to rawDealloc() for small chunks
 *)
procedure Dealloc(thread, cell)
variables
    chunk = 0,
    owner = 0,
    activeChunk = 0;
begin
    DeallocStart:
        chunk := cellOwner[cell];
        owner := chunkOwner[chunk];
        cellAllocated[cell] := FALSE;

    CheckOwner:
        if owner = thread then
            (* We own the chunk *)
            activeChunk := freeSmallChunks[thread];

            if activeChunk # NULL /\ activeChunk # chunk then
                (* Put cell into active chunk (lending logic) *)
                chunkFreeList[activeChunk] := <<cell>> \o chunkFreeList[activeChunk];
                chunkFree[activeChunk] := chunkFree[activeChunk] + CellSize;
                chunkForeignCells[activeChunk] := chunkForeignCells[activeChunk] + 1;

                (* Note: We do NOT adjust the source chunk's capacity!
                   This is key - the capacity stays reserved in source chunk *)
            else
                (* Put back into source chunk *)
                chunkFreeList[chunk] := <<cell>> \o chunkFreeList[chunk];

                if chunkFree[chunk] < CellSize then
                    (* Chunk was not active, make it active *)
                    if ~chunkInList[chunk] then
                        freeSmallChunks[thread] := chunk;
                        chunkInList[chunk] := TRUE;
                    end if;
                    chunkFree[chunk] := chunkFree[chunk] + CellSize;
                else
                    chunkFree[chunk] := chunkFree[chunk] + CellSize;

                    (* Check if chunk is completely free and no foreign cells *)
                    if chunkFree[chunk] = ChunkSize /\ chunkForeignCells[chunk] = 0 then
                        (* Free the chunk *)
                        if chunkInList[chunk] then
                            if freeSmallChunks[thread] = chunk then
                                freeSmallChunks[thread] := NULL;
                            end if;
                            chunkInList[chunk] := FALSE;
                        end if;

                        chunkOwner[chunk] := NULL;
                        chunkFreeList[chunk] := <<>>;
                        chunkFree[chunk] := 0;
                    end if;
                end if;
            end if;
        else
            (* Foreign thread owns the chunk - add to shared list *)
            atomicPrepend(sharedFreeLists[owner], cell);
        end if;

    DeallocDone:
        return;
end procedure;

(*
 * Main process for each thread
 *)
fair process thread \in Threads
variables localCell = 0;
begin
    ThreadLoop:
        while TRUE do
            either
                (* Allocate *)
                call Alloc(self, CellSize);
                localCell := cell;
            or
                (* Deallocate a previously allocated cell *)
                with c \in {ce \in 1..nextCell-1 : cellAllocated[ce] /\ cellOwner[ce] # NULL} do
                    call Dealloc(self, c);
                end with;
            or
                (* Do nothing - allow interleaving *)
                skip;
            end either;
        end while;
end process;

end algorithm; *)

====================================================================

(*
Key Issues to Check:

1. **Memory Leak via Foreign Cells**:
   - If chunk A has foreign cells and is freed, those cells become inaccessible
   - Check: NoLeakInvariant

2. **Race in compensateCounters**:
   - Multiple threads fetching from sharedFreeLists
   - Foreign cell tracking may be incorrect under concurrent modifications
   - Check: ForeignCellsAccurate

3. **Active Chunk Removal**:
   - Chunk removed from freeSmallChunks while still having foreign references
   - Other threads may still be adding to its shared list
   - This is subtle - shared list additions can happen after chunk is "freed"

4. **Double-Free**:
   - Cell added to multiple free lists
   - Check: UniqueFreeListMembership

5. **Use-After-Free**:
   - Allocated cell appears in free list
   - Check: NoAllocatedInFreeList

To verify, run with TLC model checker:
- Set Threads to {1, 2} or {1, 2, 3}
- Set MaxChunks to 2-3
- Set MaxCells to 4-6
- Check invariants and look for deadlocks or assertion violations
*)
