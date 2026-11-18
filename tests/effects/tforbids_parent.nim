discard """
  cmd: "nim check --hints:off $file"
  action: compile
  nimout: '''
tforbids_parent.nim(27, 9) Warning: writeLine(stderr, ["x"]) may have the effect WriteDirEffect forbidden by `.forbids: [WriteDirEffect]`: its effect WriteIOEffect is a parent of WriteDirEffect [Effect]
tforbids_parent.nim(31, 5) Warning: this call may have the effect NestedPoll forbidden by `.forbids: [NestedPoll]`: its effect RootEffect is a parent of NestedPoll [Effect]
tforbids_parent.nim(34, 54) Warning: act(b) may have the effect NestedPoll forbidden by `.forbids: [NestedPoll]`: its effect RootEffect is a parent of NestedPoll [Effect]
'''
"""

# An effect that is a parent of a forbidden one may be the forbidden one.
# Such code is not valid; it is a warning, not an error, so that existing code
# keeps compiling (https://github.com/nim-lang/Nim/pull/26602#issuecomment-6557818143).
# The proc type check rejects the same (tforbids_proctype_broader.nim); the
# forbidden effect itself and its children stay errors (tforbids_every.nim).

import std/os

type
  NestedPoll = object of RootEffect
  Base = ref object of RootObj

method act(b: Base) {.base.} = discard

# WriteIOEffect is a parent of WriteDirEffect
proc writer() {.forbids: [WriteDirEffect].} =
  stderr.writeLine "x"

# a call through a proc variable has the effect RootEffect
proc viaProcVar(cb: proc () {.nimcall.}) {.forbids: [NestedPoll].} =
  cb()

# so has a call of a method
proc viaMethod(b: Base) {.forbids: [NestedPoll].} = b.act()
