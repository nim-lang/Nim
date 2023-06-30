discard """
  targets: "c cpp"
"""

{.compile: "m19342.c".}

# bug #19342
type
  Node* {.bycopy.} = object
    data: array[25, cint]

proc myproc(name: cint): Node {.importc: "hello", cdecl.}

proc parse =
  let node = myproc(10)
  doAssert node.data[0] == 999

parse()
