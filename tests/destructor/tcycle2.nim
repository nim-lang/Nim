discard """
  output: "MEM 0"
  cmd: "nim c --gc:orc $file"
"""

type
  Node = ref object
    kids: seq[Node]
    data: string

proc main(x: int) =
  var n = Node(kids: @[], data: "3" & $x)
  let m = n
  n.kids.add m # MOVES can create cycles! :-(

swap root.left, someChild

proc add(s: var seq; x: sink T) =
  s[i] =sink x

proc `=sink`(dest: var T; source: T) =
  if dest != nil: destroy(dest)
  bitcopy dest, source
  markCyclic dest

type
  NodeA = ref object
    s: char
    a: array[3, NodeA]

proc m: NodeA =
  result = NodeA(s: 'a')
  result.a[0] = result
  result.a[1] = result
  result.a[2] = result

proc mainA =
  for i in 0..10:
    discard m()

let mem = getOccupiedMem()
main(90)
mainA()
GC_fullCollect()

echo "MEM ", getOccupiedMem() - mem
