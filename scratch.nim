# this is the Nim scratch file
# feel free to try out things
# when done try to run it with `compile'

# import macros
# import math
# import strutils
# import sugar
# import sequtils

var counter = 0

proc identity(arg: seq[int]): seq[int] =
  inc counter
  arg

iterator myiter(arg: openarray[int]): int =
  var i = 0
  while i < arg.len:
    yield arg[i]
    inc i

iterator myotheriter(arg: seq[int]): int =
  var i = 0
  while i < arg.len:
    yield arg[i]
    inc i


proc mymain() {.exportc.} =
  let data = @[7,4,1,1]

  counter = 0
  for it in myiter(identity(data)):
    discard

  echo "--- ", counter, " ---"
  counter = 0
  for it in myotheriter(identity(data)):
    discard

  echo "--- ", counter, " ---"

mymain()

template comment(arg: untyped) =
  discard

comment:
  for it in myiter(identity(data)):
    echo [" > ", it]

comment:
  var it: int
  var i = 0
  block :tmp4562215:
    while i < len(identity(data)):
      it = identity(data)[i]
      echo [" > ", it]
      inc i, 1

comment:
  for it in myotheriter(identity(data)):
    echo [" > ", it]

comment:
  var
    it: int
    tmp: int
  tmp = identity(data)
  var i = 0
  block tmp:
    while i < len(tmp):
      it = tmp[i]
      echo [" > ", it]
      inc i, 1
