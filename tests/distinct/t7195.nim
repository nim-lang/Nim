discard """
  cmd:      "nim c --styleCheck:hint --panics:on $options $file"
  targets:  "c"
  nimout:   ""
  action:   "compile"
  exitcode: 0
  timeout:  60.0
"""

type
  Table[K, V] = object
    key: K
    val: V

  MyTable = distinct Table[string, int]
  MyTableRef = ref MyTable

proc newTable[K, V](): ref Table[K, V] = discard

proc newMyTable: MyTableRef =
  MyTableRef(newTable[string, int]()) # <--- error here

discard newMyTable()
