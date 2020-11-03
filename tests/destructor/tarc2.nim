discard """
  output: '''leak: false'''
  cmd: '''nim c --gc:orc $file'''
"""

type
  T = ref object
    s: seq[T]
    data: string

proc create(): T = T(s: @[], data: "abc")

proc addX(x: T; data: string) =
  x.data = data

{.push sinkInference: off.}

proc addX(x: T; child: T) =
  x.s.add child

{.pop.}

proc main(rootName: string) =
  var root = create()
  root.data = rootName
  root.addX root

let mem = getOccupiedMem()
main("yeah")
GC_fullCollect()
echo "leak: ", getOccupiedMem() - mem > 0
