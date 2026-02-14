------------------------ MODULE alloc_fixed ------------------------
(*
TLA+ model showing that the SIMPLE FIX (never free small chunks) works
This should pass all invariants - NO VIOLATIONS
*)

EXTENDS Naturals, Sequences

CONSTANTS T1, T2

(*--algorithm fixed

variables
    (* Chunk state *)
    chunkOwner = T1,
    chunkFreed = FALSE,        (* This will NEVER become TRUE in the fix *)
    chunkForeignCells = 0,
    chunkFreeList = <<2>>,

    (* Shared state *)
    sharedFreeList = <<>>,

    (* Cell tracking *)
    cell1InSharedList = FALSE,
    cell1InChunkList = FALSE,
    cell1Allocated = TRUE,
    cell1Owner = T1;

define
    NoLeakInvariant ==
        chunkFreed => (Len(sharedFreeList) = 0)

    ForeignCellsZeroWhenFreed ==
        chunkFreed => (chunkForeignCells = 0)

    CellUnique ==
        (IF cell1InSharedList THEN 1 ELSE 0) +
        (IF cell1InChunkList THEN 1 ELSE 0) +
        (IF cell1Allocated THEN 1 ELSE 0) <= 1

    (* New invariant: chunk is never freed *)
    ChunkNeverFreed == ~chunkFreed
end define;

(*
 * Thread T1: Tries to free its chunk
 * FIX: Just DON'T free it!
 *)
fair process Thread1 = T1
begin
    T1_CheckFree:
        (* Check if chunk is completely free *)
        if Len(chunkFreeList) > 0 /\ chunkForeignCells = 0 then
            (* In the original code, we would free here *)
            (* FIX: Just skip the free operation! *)
            T1_SkipFree:
                (* Do nothing - chunk stays allocated and reusable *)
                skip;
        end if;
end process;

(*
 * Thread T2: Deallocates a cell
 * This is unchanged - same as before
 *)
fair process Thread2 = T2
begin
    T2_Dealloc:
        cell1Allocated := FALSE;

    T2_CheckOwner:
        if chunkOwner = T1 then
            T2_AddToShared:
                (* This is safe now because chunk is never freed *)
                sharedFreeList := Append(sharedFreeList, 1);
                cell1InSharedList := TRUE;
        end if;
end process;

(*
 * Thread T1: Processes its shared list
 * This is unchanged
 *)
fair process Thread1_Fetch = T1 + 100
begin
    T1_FetchShared:
        if Len(sharedFreeList) > 0 then
            (* This check is now always true *)
            await ~chunkFreed;

            T1_ProcessShared:
                chunkFreeList := chunkFreeList \o sharedFreeList;
                cell1InSharedList := FALSE;
                cell1InChunkList := TRUE;
                sharedFreeList := <<>>;
        end if;
end process;

end algorithm; *)

\* Translation would go here (run pcal.trans to generate)

====================================================================

(*
EXPECTED RESULT:
- NO VIOLATIONS
- All invariants pass:
  ✓ NoLeakInvariant: trivially true (chunkFreed always FALSE)
  ✓ ForeignCellsZeroWhenFreed: trivially true
  ✓ CellUnique: still enforced
  ✓ ChunkNeverFreed: by construction

PROOF SKETCH:
The race condition cannot occur because the dangerous operation
(freeing the chunk) is simply never executed. The chunk remains
allocated and can safely receive cells via sharedFreeList at any time.

Timeline with fix:
  t₁: T1 checks conditions
  t₂: T2 starts dealloc
  t₃: T1 decides NOT to free (skips operation)
  t₄: T2 checks owner (still valid)
  t₅: T2 adds to sharedFreeList (safe - chunk still exists)
  t₆: T1 later fetches from sharedFreeList (safe - chunk still exists)

There is no use-after-free because there is no free.
*)
