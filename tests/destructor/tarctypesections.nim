discard """
  output: "MEM 0"
  cmd: "nim c --gc:arc $file"
"""

type
  RefNode = ref object
    le, ri: RefNode
    name: char

proc edge0(a, b: RefNode) =
  if a.le == nil: a.le = b
  else: a.ri = b

proc createNode0(name: char): RefNode =
  new result
  result.name = name

proc main0 =
  let r = createNode0('R')
  let c = createNode0('C')
  c.edge0 r


type
  NodeDesc = object
    le, ri: Node
    name: char
  Node = ref NodeDesc

proc edge(a, b: Node) =
  if a.le == nil: a.le = b
  else: a.ri = b

proc createNode(name: char): Node =
  new result
  result.name = name

proc main =
  let r = createNode('R')
  let c = createNode('C')
  c.edge r


type
  NodeB = ref NodeBo
  NodeBo = object
    le, ri: NodeB
    name: char

proc edge(a, b: NodeB) =
  if a.le == nil: a.le = b
  else: a.ri = b

proc createNodeB(name: char): NodeB =
  new result
  result.name = name


proc mainB =
  let r = createNodeB('R')
  let c = createNodeB('C')
  c.edge r


let memB = getOccupiedMem()
main0()
main()
mainB()
echo "MEM ", getOccupiedMem() - memB
