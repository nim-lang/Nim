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
$nimsuggest --tester $file
>sug $1
sug;;skProc;;tables.hasKey;;proc (t: Table[hasKey.A, hasKey.B], key: A): bool;;*/lib/pure/collections/tables.nim;;374;;5;;"Returns true if*";;100;;None
sug;;skProc;;tables.add;;proc (t: var Table[add.A, add.B], key: A, val: sink B);;*/lib/pure/collections/tables.nim;;505;;5;;"Puts a new*";;100;;None
sug;;skIterator;;tables.allValues;;iterator (t: Table[allValues.A, allValues.B], key: A): B{.inline.};;*/lib/pure/collections/tables.nim;;769;;9;;"Iterates over any*";;100;;None
sug;;skProc;;tables.clear;;proc (t: var Table[clear.A, clear.B]);;*/lib/pure/collections/tables.nim;;567;;5;;"Resets the table so that it is empty.*";;100;;None
sug;;skProc;;tables.contains;;proc (t: Table[contains.A, contains.B], key: A): bool;;*/lib/pure/collections/tables.nim;;392;;5;;"Alias of `hasKey*";;100;;None
*
"""

# TODO: test/fix suggestion sorting - deprecated suggestions should rank lower
