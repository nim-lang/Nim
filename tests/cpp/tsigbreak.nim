discard """
  targets: "cpp"
  action: compile
"""

import tables, lists

type
  ListTable[K, V] = object
    table: Table[K, DoublyLinkedNode[V]]

proc initListTable*[K, V](initialSize = 64): ListTable[K, V] =
  result.table = initTable[K, DoublyLinkedNode[V]]()

proc `[]=`*[K, V](t: var ListTable[K, V], key: K, val: V) =
  t.table[key].value = val

type
  SomeObj = object
  OtherObj = object

proc main() =
  var someTable = initListTable[int, SomeObj]()
  var otherTable = initListTable[int, OtherObj]()

  someTable[1] = SomeObj()
  otherTable[42] = OtherObj()

main()
