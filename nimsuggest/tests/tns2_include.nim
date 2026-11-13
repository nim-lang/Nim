# A query on a file the project includes is answered for the module including
# it, as `nim ns` reported: `def` finds the type that module declares.

import ns2incl

discard make()

discard """
$nimsuggest2 $file
!copy fixtures/mns2incl.nim ns2incl.nim
!copy fixtures/mns2inclbody.nim ns2inclbody.nim
>changed $file
>known $path/ns2inclbody.nim
true
>def $path/ns2inclbody.nim:1:15
def;;skType;;ns2incl.Base;;Base;;*/ns2incl.nim;;1;;5;;""
!del ns2incl.nim
!del ns2inclbody.nim
"""
