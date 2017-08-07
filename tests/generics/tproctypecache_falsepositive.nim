
import asyncdispatch

type
  Callback = proc() {.closure, gcsafe.}
  GameState = ref object
    playerChangeHandlers: seq[Callback]

#proc dummy() =
#  var x = newSeq[proc() {.cdecl, gcsafe.}]()

proc newGameState(): GameState =
  result = GameState(
    playerChangeHandlers: newSeq[Callback]() # this fails
  )

#dummy()
