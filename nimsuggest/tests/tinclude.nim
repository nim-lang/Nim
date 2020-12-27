# import that has an include, def calls must work into and out of includes
import fixtures/minclude_import

proc go() =
  discard create().say()

go()

discard """
$nimsuggest --tester $file
>def $path/tinclude.nim:5:14
def;;skProc;;minclude_import.create;;proc (greeting: string, subject: string): Greet{.noSideEffect, gcsafe, locks: 0.};;*fixtures/minclude_include.nim;;3;;5;;"";;100
>def $path/fixtures/minclude_include.nim:3:71
def;;skType;;minclude_types.Greet;;Greet;;*fixtures/minclude_types.nim;;4;;2;;"";;100
>def $path/fixtures/minclude_include.nim:3:71
def;;skType;;minclude_types.Greet;;Greet;;*fixtures/minclude_types.nim;;4;;2;;"";;100
"""

# TODO test/fix if the first `def` is not first or repeated we get no results
