# Test basic module dependency recompilations.

import dep

proc main(f: Foo) =
  f.#[!]#

# the tester supports the spec section at the bottom of the file and
# this way, the line numbers more often stay the same

discard """
!copy fixtures/mdep_v1.nim dep.nim
$nimsuggest --tester $file
>sug $1
sug;;skField;;x;;int;;*dep.nim;;8;;4;;"";;100;;None
sug;;skField;;y;;int;;*dep.nim;;8;;8;;"";;100;;None
sug;;skProc;;tdot3.main;;proc (f: Foo);;$file;;5;;5;;"";;100;;None

!copy fixtures/mdep_v2.nim dep.nim
>mod $path/dep.nim
>sug $1
sug;;skField;;x;;int;;*dep.nim;;8;;4;;"";;100;;None
sug;;skField;;y;;int;;*dep.nim;;8;;8;;"";;100;;None
sug;;skField;;z;;string;;*dep.nim;;9;;4;;"";;100;;None
sug;;skProc;;tdot3.main;;proc (f: Foo);;$file;;5;;5;;"";;100;;None
!del dep.nim
"""
