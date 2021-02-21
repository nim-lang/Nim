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

# the maxresults are limited as it seems there is sort or some other
# instability that causes the suggestions to slightly differ between 32 bit
# and 64 bit versions of nimsuggest

discard """
disabled:true
$nimsuggest --tester --maxresults:4 $file
>sug $1
sug;;skProc;;tables.hasKey;;proc (t: Table[hasKey.A, hasKey.B], key: A): bool;;*/lib/pure/collections/tables.nim;;374;;5;;"Returns true *";;100;;None
sug;;skProc;;tables.clear;;proc (t: var Table[clear.A, clear.B]);;*/lib/pure/collections/tables.nim;;567;;5;;"Resets the table so that it is empty*";;100;;None
sug;;skProc;;tables.contains;;proc (t: Table[contains.A, contains.B], key: A): bool;;*/lib/pure/collections/tables.nim;;*;;5;;"Alias of *";;100;;None
sug;;skProc;;tables.del;;proc (t: var Table[del.A, del.B], key: A);;*/lib/pure/collections/tables.nim;;*;;5;;"*";;100;;None
"""

# TODO enable the tests
# TODO: test/fix suggestion sorting - deprecated suggestions should rank lower
