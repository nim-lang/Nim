---- MODULE alloc_focused_TTrace_1770904854 ----
EXTENDS Sequences, TLCExt, Toolbox, Naturals, TLC, alloc_focused

_expression ==
    LET alloc_focused_TEExpression == INSTANCE alloc_focused_TEExpression
    IN alloc_focused_TEExpression!expression
----

_trace ==
    LET alloc_focused_TETrace == INSTANCE alloc_focused_TETrace
    IN alloc_focused_TETrace!trace
----

_inv ==
    ~(
        TLCGet("level") = Len(_TETrace)
        /\
        cell1Owner = (1)
        /\
        sharedFreeList = (<<1>>)
        /\
        cell1InSharedList = (TRUE)
        /\
        pc = ((1 :> "Done" @@ 2 :> "Done" @@ 101 :> "T1_FetchShared"))
        /\
        chunkOwner = (0)
        /\
        cell1Allocated = (FALSE)
        /\
        cell1InChunkList = (FALSE)
        /\
        chunkForeignCells = (0)
        /\
        chunkFreed = (TRUE)
        /\
        chunkFreeList = (<<>>)
    )
----

_init ==
    /\ cell1InChunkList = _TETrace[1].cell1InChunkList
    /\ cell1Allocated = _TETrace[1].cell1Allocated
    /\ cell1InSharedList = _TETrace[1].cell1InSharedList
    /\ chunkFreeList = _TETrace[1].chunkFreeList
    /\ sharedFreeList = _TETrace[1].sharedFreeList
    /\ chunkOwner = _TETrace[1].chunkOwner
    /\ chunkFreed = _TETrace[1].chunkFreed
    /\ cell1Owner = _TETrace[1].cell1Owner
    /\ pc = _TETrace[1].pc
    /\ chunkForeignCells = _TETrace[1].chunkForeignCells
----

_next ==
    /\ \E i,j \in DOMAIN _TETrace:
        /\ \/ /\ j = i + 1
              /\ i = TLCGet("level")
        /\ cell1InChunkList  = _TETrace[i].cell1InChunkList
        /\ cell1InChunkList' = _TETrace[j].cell1InChunkList
        /\ cell1Allocated  = _TETrace[i].cell1Allocated
        /\ cell1Allocated' = _TETrace[j].cell1Allocated
        /\ cell1InSharedList  = _TETrace[i].cell1InSharedList
        /\ cell1InSharedList' = _TETrace[j].cell1InSharedList
        /\ chunkFreeList  = _TETrace[i].chunkFreeList
        /\ chunkFreeList' = _TETrace[j].chunkFreeList
        /\ sharedFreeList  = _TETrace[i].sharedFreeList
        /\ sharedFreeList' = _TETrace[j].sharedFreeList
        /\ chunkOwner  = _TETrace[i].chunkOwner
        /\ chunkOwner' = _TETrace[j].chunkOwner
        /\ chunkFreed  = _TETrace[i].chunkFreed
        /\ chunkFreed' = _TETrace[j].chunkFreed
        /\ cell1Owner  = _TETrace[i].cell1Owner
        /\ cell1Owner' = _TETrace[j].cell1Owner
        /\ pc  = _TETrace[i].pc
        /\ pc' = _TETrace[j].pc
        /\ chunkForeignCells  = _TETrace[i].chunkForeignCells
        /\ chunkForeignCells' = _TETrace[j].chunkForeignCells

\* Uncomment the ASSUME below to write the states of the error trace
\* to the given file in Json format. Note that you can pass any tuple
\* to `JsonSerialize`. For example, a sub-sequence of _TETrace.
    \* ASSUME
    \*     LET J == INSTANCE Json
    \*         IN J!JsonSerialize("alloc_focused_TTrace_1770904854.json", _TETrace)

=============================================================================

 Note that you can extract this module `alloc_focused_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `alloc_focused_TEExpression.tla` file takes precedence 
  over the module `alloc_focused_TEExpression` below).

---- MODULE alloc_focused_TEExpression ----
EXTENDS Sequences, TLCExt, Toolbox, Naturals, TLC, alloc_focused

expression == 
    [
        \* To hide variables of the `alloc_focused` spec from the error trace,
        \* remove the variables below.  The trace will be written in the order
        \* of the fields of this record.
        cell1InChunkList |-> cell1InChunkList
        ,cell1Allocated |-> cell1Allocated
        ,cell1InSharedList |-> cell1InSharedList
        ,chunkFreeList |-> chunkFreeList
        ,sharedFreeList |-> sharedFreeList
        ,chunkOwner |-> chunkOwner
        ,chunkFreed |-> chunkFreed
        ,cell1Owner |-> cell1Owner
        ,pc |-> pc
        ,chunkForeignCells |-> chunkForeignCells
        
        \* Put additional constant-, state-, and action-level expressions here:
        \* ,_stateNumber |-> _TEPosition
        \* ,_cell1InChunkListUnchanged |-> cell1InChunkList = cell1InChunkList'
        
        \* Format the `cell1InChunkList` variable as Json value.
        \* ,_cell1InChunkListJson |->
        \*     LET J == INSTANCE Json
        \*     IN J!ToJson(cell1InChunkList)
        
        \* Lastly, you may build expressions over arbitrary sets of states by
        \* leveraging the _TETrace operator.  For example, this is how to
        \* count the number of times a spec variable changed up to the current
        \* state in the trace.
        \* ,_cell1InChunkListModCount |->
        \*     LET F[s \in DOMAIN _TETrace] ==
        \*         IF s = 1 THEN 0
        \*         ELSE IF _TETrace[s].cell1InChunkList # _TETrace[s-1].cell1InChunkList
        \*             THEN 1 + F[s-1] ELSE F[s-1]
        \*     IN F[_TEPosition - 1]
    ]

=============================================================================



Parsing and semantic processing can take forever if the trace below is long.
 In this case, it is advised to uncomment the module below to deserialize the
 trace from a generated binary file.

\*
\*---- MODULE alloc_focused_TETrace ----
\*EXTENDS IOUtils, TLC, alloc_focused
\*
\*trace == IODeserialize("alloc_focused_TTrace_1770904854.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE alloc_focused_TETrace ----
EXTENDS TLC, alloc_focused

trace == 
    <<
    ([cell1Owner |-> 1,sharedFreeList |-> <<>>,cell1InSharedList |-> FALSE,pc |-> (1 :> "T1_CheckFree" @@ 2 :> "T2_Dealloc" @@ 101 :> "T1_FetchShared"),chunkOwner |-> 1,cell1Allocated |-> TRUE,cell1InChunkList |-> FALSE,chunkForeignCells |-> 0,chunkFreed |-> FALSE,chunkFreeList |-> <<2>>]),
    ([cell1Owner |-> 1,sharedFreeList |-> <<>>,cell1InSharedList |-> FALSE,pc |-> (1 :> "T1_FreeChunk" @@ 2 :> "T2_Dealloc" @@ 101 :> "T1_FetchShared"),chunkOwner |-> 1,cell1Allocated |-> TRUE,cell1InChunkList |-> FALSE,chunkForeignCells |-> 0,chunkFreed |-> FALSE,chunkFreeList |-> <<2>>]),
    ([cell1Owner |-> 1,sharedFreeList |-> <<>>,cell1InSharedList |-> FALSE,pc |-> (1 :> "T1_FreeChunk" @@ 2 :> "T2_CheckOwner" @@ 101 :> "T1_FetchShared"),chunkOwner |-> 1,cell1Allocated |-> FALSE,cell1InChunkList |-> FALSE,chunkForeignCells |-> 0,chunkFreed |-> FALSE,chunkFreeList |-> <<2>>]),
    ([cell1Owner |-> 1,sharedFreeList |-> <<>>,cell1InSharedList |-> FALSE,pc |-> (1 :> "T1_FreeChunk" @@ 2 :> "T2_AddToShared" @@ 101 :> "T1_FetchShared"),chunkOwner |-> 1,cell1Allocated |-> FALSE,cell1InChunkList |-> FALSE,chunkForeignCells |-> 0,chunkFreed |-> FALSE,chunkFreeList |-> <<2>>]),
    ([cell1Owner |-> 1,sharedFreeList |-> <<>>,cell1InSharedList |-> FALSE,pc |-> (1 :> "Done" @@ 2 :> "T2_AddToShared" @@ 101 :> "T1_FetchShared"),chunkOwner |-> 0,cell1Allocated |-> FALSE,cell1InChunkList |-> FALSE,chunkForeignCells |-> 0,chunkFreed |-> TRUE,chunkFreeList |-> <<>>]),
    ([cell1Owner |-> 1,sharedFreeList |-> <<1>>,cell1InSharedList |-> TRUE,pc |-> (1 :> "Done" @@ 2 :> "Done" @@ 101 :> "T1_FetchShared"),chunkOwner |-> 0,cell1Allocated |-> FALSE,cell1InChunkList |-> FALSE,chunkForeignCells |-> 0,chunkFreed |-> TRUE,chunkFreeList |-> <<>>])
    >>
----


=============================================================================

---- CONFIG alloc_focused_TTrace_1770904854 ----
CONSTANTS
    T1 = 1
    T2 = 2

INVARIANT
    _inv

CHECK_DEADLOCK
    \* CHECK_DEADLOCK off because of PROPERTY or INVARIANT above.
    FALSE

INIT
    _init

NEXT
    _next

CONSTANT
    _TETrace <- _trace

ALIAS
    _expression
=============================================================================
\* Generated on Thu Feb 12 15:00:54 CET 2026