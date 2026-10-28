# An extra root deleted after a query made it one must not stop `nim ns`: every
# run failed on it, so a module the project started to import was never known.

import ns2rootmid

echo mid()

discard """
$nimsuggest2 $file
!copy fixtures/mns2rootmid_v1.nim ns2rootmid.nim
!copy fixtures/mns2rootlone.nim ns2rootlone.nim
>changed $file
>def $path/ns2rootlone.nim:3:6
def;;skProc;;ns2rootlone.greet;;proc (): string{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2rootlone.nim;;3;;5;;""
!del ns2rootlone.nim
!copy fixtures/mns2rootmid_v2.nim ns2rootmid.nim
!copy fixtures/mns2rootnew.nim ns2rootnew.nim
>changed $file
>known $path/ns2rootnew.nim
true
!del ns2rootmid.nim
!del ns2rootnew.nim
"""
