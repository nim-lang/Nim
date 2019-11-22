discard """
  output: '''leak: true'''
  cmd: '''nim c --gc:arc $file'''
"""

type
  T = ref object
    s: seq[T]
    data: string

proc create(): T = T(s: @[], data: "abc")

proc addX(x: T; data: string) =
  x.data = data

proc addX(x: T; child: T) =
  x.s.add child

proc main(rootName: string) =
  var root = create()
  root.data = rootName
  # this implies we do the refcounting wrong. We should leak memory here
  # and not create a destruction cycle:
  root.addX root

let mem = getOccupiedMem()
main("yeah")
# since we created a retain cycle, we MUST leak memory here:
echo "leak: ", getOccupiedMem() - mem > 0
