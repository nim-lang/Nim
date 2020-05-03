discard """
  output: "MEM 0"
  cmd: "nim c --gc:orc $file"
"""

type
  Node = ref object of RootObj
    le, ri: Node
    name: char

proc edge(a, b: Node) =
  if a.le == nil: a.le = b
  else: a.ri = b

proc createNode(name: char): Node =
  new result
  result.name = name

#[

+---------+      +------+
|         |      |      |
|  A      +----->+      <------+-------------+
+--+------+      |      |      |             |
   |             |      |      |     C       |
   |             |  R   |      |             |
+--v------+      |      |      +-------------+
|         |      |      |        ^
|   B     <------+      |        |
|         |      |      +--------+
+---------+      |      |
                 +------+

]#

proc main =
  let a = createNode('A')
  let b = createNode('B')
  let r = createNode('R')
  let c = createNode('C')

  a.edge b
  a.edge r

  r.edge b
  r.edge c

  c.edge r


let mem = getOccupiedMem()
main()
GC_fullCollect()
echo "MEM ", getOccupiedMem() - mem
