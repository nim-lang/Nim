discard """
  input: "hi"
  output: '''
hi
Nim
'''
  matrix: "--gc:arc -d:useMalloc; --gc:arc"
"""
{.experimental: "views".}

block: # bug 18627
  proc setPosition(params: openArray[string]) =
    for i in params.toOpenArray(0, params.len - 1):
      echo i

  proc uciLoop() =
    let params = @[readLine(stdin)]
    setPosition(params)

  uciLoop()

  proc uciLoop2() =
    let params = @["Nim"]
    for i in params.toOpenArray(0, params.len - 1):
      echo i
  uciLoop2()

when defined(nimPreviewSlimSystem):
  import std/assertions

block: # bug #20954
  block:
    doAssertRaises(IndexDefect):
      var v: array[10, int]

      echo len(toOpenArray(v, 20, 30))

  block:
    doAssertRaises(IndexDefect):
      var v: seq[int]

      echo len(toOpenArray(v, 20, 30))

# bug #20422

proc f(a: var string) =
  var v = a.toOpenArray(1, 3)
  v[0] = 'a'

var a = "Hello"
f(a)
doAssert a == "Hallo"
