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
  n.kids.add m

let mem = getOccupiedMem()
main(90)
echo "MEM ", getOccupiedMem() - mem
