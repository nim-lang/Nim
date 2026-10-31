discard """
  cmd: "nim check --hints:off $file"
  action: reject
  nimout: '''
tforbids_proctype_broader.nim(20, 57) Error: type mismatch: got <proc (){.gcsafe.}> but expected 'proc (){.nimcall.}'
  The effect WriteIOEffect is forbidden by `.forbids: [WriteDirEffect]` (WriteIOEffect is a parent of WriteDirEffect, so it may be WriteDirEffect)
  tforbids_proctype_broader.nim(19, 23) effect propagated from here: writeLine(stderr, ["x"])
tforbids_proctype_broader.nim(25, 47) Error: type mismatch: got <proc (){.gcsafe.}> but expected 'proc (){.nimcall.}'
  The effect RootEffect is forbidden by `.forbids: [Exec]` (RootEffect is a parent of Exec, so it may be Exec)
'''
"""

# issue #26514: the forbidden effect is not visible in the code at hand

import std/[os, logging]

# WriteIOEffect is a parent of WriteDirEffect, so `.forbids: [WriteDirEffect]`
# rejects it.
proc writer() = stderr.writeLine("x")
let w: proc () {.nimcall, forbids: [WriteDirEffect].} = writer

# A call through a method has the effect RootEffect.
type Exec = object of RootEffect
proc logger() = info("x")
let l: proc () {.nimcall, forbids: [Exec].} = logger
