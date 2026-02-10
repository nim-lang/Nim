
type
  Table[K, V] = object
    key: K
    val: V

  MyTable = distinct Table[string, int]
  MyTableRef = ref MyTable

# Section: Distinct ref alias can wrap a generic ref-returning constructor.
proc newTable[K, V](): ref Table[K, V] = discard

proc newMyTable: MyTableRef =
  MyTableRef(newTable[string, int]()) # <--- error here

discard newMyTable()
