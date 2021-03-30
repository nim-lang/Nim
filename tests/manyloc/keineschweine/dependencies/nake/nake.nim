discard """
DO AS THOU WILST PUBLIC LICENSE

Whoever should stumble upon this document is henceforth and forever
entitled to DO AS THOU WILST with aforementioned document and the
contents thereof.

As said in the Olde Country, `Keepe it Gangster'."""

#[
xxx remove this? seems mostly duplicate of: tests/manyloc/nake/nake.nim
]#

import strutils, parseopt, tables, os

type
  PTask* = ref object
    desc*: string
    action*: TTaskFunction
  TTaskFunction* = proc() {.closure.}
var
  tasks* = initTable[string, PTask](16)

proc newTask*(desc: string; action: TTaskFunction): PTask
proc runTask*(name: string) {.inline.}
proc shell*(cmd: varargs[string, `$`]): int {.discardable.}
proc cd*(dir: string) {.inline.}

template nakeImports*(): stmt {.immediate.} =
  import tables, parseopt, strutils, os

template task*(name: string; description: string; body: stmt): stmt {.dirty, immediate.} =
  block:
    var t = newTask(description, proc() {.closure.} =
      body)
    tasks[name] = t

proc newTask*(desc: string; action: TTaskFunction): PTask =
  new(result)
  result.desc = desc
  result.action = action
proc runTask*(name: string) = tasks[name].action()

proc shell*(cmd: varargs[string, `$`]): int =
  result = execShellCmd(cmd.join(" "))
proc cd*(dir: string) = setCurrentDir(dir)
template withDir*(dir: string; body: stmt): stmt =
  ## temporary cd
  ## withDir "foo":
  ##   # inside foo
  ## #back to last dir
  var curDir = getCurrentDir()
  cd(dir)
  body
  cd(curDir)

when true:
  if not fileExists("nakefile.nim"):
    echo "No nakefile.nim found. Current working dir is ", getCurrentDir()
    quit 1
  var args = ""
  for i in 1..paramCount():
    args.add paramStr(i)
    args.add " "
  quit(shell("nim", "c", "-r", "nakefile.nim", args))
else:
  import std/exitprocs
  addExitProc(proc() {.noconv.} =
    var
      task: string
      printTaskList: bool
    for kind, key, val in getOpt():
      case kind
      of cmdLongOption, cmdShortOption:
        case key.tolower
        of "tasks", "t":
          printTaskList = true
        else:
          echo "Unknown option: ", key, ": ", val
      of cmdArgument:
        task = key
      else: nil
    if printTaskList or task.isNil or not(tasks.hasKey(task)):
      echo "Available tasks:"
      for name, task in pairs(tasks):
        echo name, " - ", task.desc
      quit 0
    tasks[task].action())
