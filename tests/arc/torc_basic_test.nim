discard """
  output: "MEM 0"
  cmd: "nim c --gc:orc $file"
"""

type
  Node = ref object
    name: char
    sccId: int
    #a: array[3, Node]
    a0, a1, a2: Node
    rc: int

proc edge(a, b: Node) =
  inc b.rc
  if a.a0 == nil: a.a0 = b
  elif a.a1 == nil: a.a1 = b
  else: a.a2 = b
  when false:
    var i = 0
    while a.a[i] != nil: inc i
    a.a[i] = b

proc createNode(name: char): Node =
  new result
  result.name = name

#[

     +--------------------------------+
     v                                |
+---------+      +------+             |
|         |      |      |             |
|  A      +----->+      |      +------+------+
+--+------+      |      |      |             |
   |             |      |      |     C       ------------>  G  <--|
   |             |  R   |      |             |
+--v------+      |      |      +-------------+
|         |      |      |        ^
|   B     <------+      |        |
|         |      |      +--------+
+---------+      |      |
                 +------+

]#
proc use(x: Node) = discard

proc main =
  let a = createNode('A')
  let b = createNode('B')
  let r = createNode('R')
  let c = createNode('C')

  a.edge b
  a.edge r

  r.edge b
  r.edge c

  let g = createNode('G')
  g.edge g
  g.edge g

  c.edge g
  c.edge a

  use g
  use b

proc buildComplexGraph: Node =
  # see https://en.wikipedia.org/wiki/Strongly_connected_component for the
  # graph:
  let a = createNode('a')
  let b = createNode('b')
  let c = createNode('c')
  let d = createNode('d')
  let e = createNode('e')

  a.edge c
  c.edge b
  c.edge e
  b.edge a
  d.edge c
  e.edge d


  let f = createNode('f')
  b.edge f
  e.edge f

  let g = createNode('g')
  let h = createNode('h')
  let i = createNode('i')

  f.edge g
  f.edge i
  g.edge h
  h.edge i
  i.edge g

  let j = createNode('j')

  h.edge j
  i.edge j

  let k = createNode('k')
  let l = createNode('l')

  f.edge k
  k.edge l
  l.edge k
  k.edge j

  let m = createNode('m')
  let n = createNode('n')
  let p = createNode('p')
  let q = createNode('q')

  m.edge n
  n.edge p
  n.edge q
  q.edge p
  p.edge m

  q.edge k

  d.edge m
  e.edge n

  result = a

proc main2 =
  let g = buildComplexGraph()

main()
main2()
GC_fullCollect()
echo "MEM ", getOccupiedMem()
