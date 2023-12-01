discard """
  output: "true"
"""

type
  Idx = object
    i: int
  Node = object
    n: int
    next: seq[Idx]
  FooBar = object
    s: seq[Node]

proc `=copy`(dest: var Idx; source: Idx) {.error.}
proc `=copy`(dest: var Node; source: Node) {.error.}
proc `=copy`(dest: var FooBar; source: FooBar) {.error.}

proc doSomething(ss: var seq[int], s: FooBar) =
  for i in 0 .. s.s.len-1:
    for elm in items s.s[i].next:
      ss.add s.s[elm.i].n

when isMainModule:
  const foo = FooBar(s: @[Node(n: 1, next: @[Idx(i: 0)])])
  var ss: seq[int]
  doSomething(ss, foo)
  echo ss == @[1]
