# A module compiled on top of an unsaved buffer is not written to the NIF cache,
# so the next nimsuggest does not load declarations built from code that was
# never saved.

import mictaint, mictaintuser

discard getX(Foo())

discard """
$nimsuggest --v3 --tester $file
>def $file:7:9
def;;skProc;;mictaintuser.getX;;proc (f: Foo): int*;;*mictaintuser.nim;;3;;5;;"";;100
>def $path/mictaint.nim;$path/fixtures/mictaint_dirty.nim:3:4
def;;skField;;mictaint.Foo.x;;string;;*mictaint.nim;;3;;4;;"";;100
>def $file:7:9
def;;skProc;;mictaintuser.getX;;proc (f: Foo): string*;;*mictaintuser.nim;;3;;5;;"";;100
!restart
>def $file:7:9
def;;skProc;;mictaintuser.getX;;proc (f: Foo): int*;;*mictaintuser.nim;;3;;5;;"";;100
"""
