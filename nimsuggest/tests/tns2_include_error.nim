# A module whose include was saved with an error fails to build in `nim ns`
# and keeps its NIF, which must not be loaded: `highlight` compiles this file
# (the def twice) instead of answering from the NIFs (two results).

import ns2inclerr

proc shout(s: string): string = s & "!"

discard shout($make().x)

discard """
$nimsuggest2 $file
!copy fixtures/mns2inclerr.nim ns2inclerr.nim
!copy fixtures/mns2inclbody.nim ns2inclerrbody.nim
>changed $file
!copy fixtures/mns2inclbody_v2.nim ns2inclerrbody.nim
>highlight $file:9:9
def;;skProc;;tns2_include_error.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;7;;5;;""
def;;skProc;;tns2_include_error.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;7;;5;;""
use;;skProc;;tns2_include_error.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;9;;8;;""
!del ns2inclerr.nim
!del ns2inclerrbody.nim
"""
