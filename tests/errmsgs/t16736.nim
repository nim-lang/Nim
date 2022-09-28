discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t16736.nim(12, 7) Error: invalid type: 'ProcType' for const
t16736.nim(14, 7) Error: invalid type: 'proc (){.closure, noSideEffect, gcsafe, locks: 0.}' for const
'''
"""


type ProcType = proc()
const a: ProcType = proc() = discard

const b = proc() {.closure.} = discard
