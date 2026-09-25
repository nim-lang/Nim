discard """
output: '''ok'''
"""

# IC gives each field use a fresh `skField` stub. The first read below must
# still alias the later nested read so move analysis doesn't clear `program`.
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
