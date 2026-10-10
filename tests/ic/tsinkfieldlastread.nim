discard """
output: '''ok'''
"""

# A field use loaded from a NIF must be the field symbol of its object. The
# first read below must alias the later nested read, or move analysis clears
# `program`.
type
  Program = ref object
    revision: int
  Snapshot = tuple[program: Program]
  State = object
    observedProgram: Program
    observedRevision: int

proc snapshot(): Snapshot =
  result.program = Program(revision: 7)

proc consume(state: var State) =
  let pending = snapshot()
  state.observedProgram = pending.program
  state.observedRevision = pending.program.revision

var state: State
consume(state)
doAssert state.observedProgram.revision == 7
doAssert state.observedRevision == 7
echo "ok"
