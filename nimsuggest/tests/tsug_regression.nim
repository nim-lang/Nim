# test we only get suggestions, not error messages:

import tables, sets, parsecfg

type X = object

proc main =
  # bug #52
  var
    set0 = initHashSet[int]()
    set1 = initHashSet[X]()
    set2 = initHashSet[ref int]()

    map0 = initTable[int, int]()
    map1 = initOrderedTable[string, int]()
    cfg = loadConfig("file")
  map0.#[!]#

discard """
disabled:true
$nimsuggest --tester $file
>sug $1
sug;;skProc;;tables.getOrDefault;;proc (t: Table[getOrDefault.A, getOrDefault.B], key: A): B;;$lib/pure/collections/tables.nim;;178;;5;;"";;100;;None
sug;;skProc;;tables.hasKey;;proc (t: Table[hasKey.A, hasKey.B], key: A): bool;;$lib/pure/collections/tables.nim;;233;;5;;"returns true iff `key` is in the table `t`.";;100;;None
sug;;skProc;;tables.add;;proc (t: var Table[add.A, add.B], key: A, val: B);;$lib/pure/collections/tables.nim;;309;;5;;"puts a new (key, value)-pair into `t` even if ``t[key]`` already exists.";;100;;None
sug;;skIterator;;tables.allValues;;iterator (t: Table[allValues.A, allValues.B], key: A): B{.inline.};;$lib/pure/collections/tables.nim;;225;;9;;"iterates over any value in the table `t` that belongs to the given `key`.";;100;;None
sug;;skProc;;tables.clear;;proc (t: var Table[clear.A, clear.B]);;$lib/pure/collections/tables.nim;;121;;5;;"Resets the table so that it is empty.";;100;;None
*
"""
