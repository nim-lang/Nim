discard """
  cmd: "nim check --hints:off $file"
  action: reject
  nimout: '''
tforbids_proctype.nim(31, 15) Error: type mismatch: got <proc (){.noSideEffect, gcsafe.}> but expected 'Tool = proc (){.nimcall.}'
  The effect Exec is forbidden by `.forbids: [Exec]`
  tforbids_proctype.nim(28, 21) effect propagated from here: helper()
  tforbids_proctype.nim(27, 20) effect propagated from here: run()
  tforbids_proctype.nim(26, 21) effect propagated from here: Exec
tforbids_proctype.nim(34, 7) Error: type mismatch: got <proc (){.noSideEffect, gcsafe.}>
  but expression 'tool' is of type: proc (){.noSideEffect, gcsafe.}
  The effect Exec is forbidden by `.forbids: [Exec]`
  tforbids_proctype.nim(28, 21) effect propagated from here: helper()
  tforbids_proctype.nim(27, 20) effect propagated from here: run()
  tforbids_proctype.nim(26, 21) effect propagated from here: Exec
tforbids_proctype.nim(38, 22) Error: type mismatch: got <proc (){.noSideEffect, gcsafe.}> but expected 'Listed = proc (){.nimcall.}'
  The effect Exec is not listed in `.tags: [Other]`
  tforbids_proctype.nim(28, 21) effect propagated from here: helper()
  tforbids_proctype.nim(27, 20) effect propagated from here: run()
  tforbids_proctype.nim(26, 21) effect propagated from here: Exec
'''
"""

# issue #26514
type Exec = object of RootEffect
proc run() {.tags: [Exec].} = discard
proc helper() = run()
proc tool() = helper()

type Tool = proc () {.nimcall, forbids: [Exec].}
let t: Tool = tool

proc caller(p: proc () {.nimcall, forbids: [Exec].}) = p()
caller(tool)

type Other = object of RootEffect
type Listed = proc () {.nimcall, tags: [Other].}
let listed: Listed = tool
