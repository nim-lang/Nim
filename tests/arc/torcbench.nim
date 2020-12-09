discard """
  output: '''true peak memory: true'''
  cmd: "nim c --gc:orc -d:release $file"
"""

import lists, strutils, times

type
  Base = ref object of RootObj

  Node = ref object of Base
    parent: DoublyLinkedList[string]
    le, ri: Node
    self: Node # in order to create a cycle

proc buildTree(parent: DoublyLinkedList[string]; depth: int): Node =
  if depth == 0:
    result = nil
  elif depth == 1:
    result = Node(parent: parent, le: nil, ri: nil, self: nil)
    when not defined(gcArc):
      result.self = result
  else:
    result = Node(parent: parent, le: buildTree(parent, depth - 1), ri: buildTree(parent, depth - 2), self: nil)
    result.self = result

proc main() =
  for i in countup(1, 100):
    var leakList = initDoublyLinkedList[string]()
    for j in countup(1, 5000):
      leakList.append(newString(200))
    #GC_fullCollect()
    for i in 0..400:
      discard buildTree(leakList, 8)

main()
GC_fullCollect()
echo getOccupiedMem() < 10 * 1024 * 1024, " peak memory: ", getMaxMem() < 10 * 1024 * 1024
