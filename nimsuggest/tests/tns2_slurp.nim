# A module that reads a file with `staticRead` is rebuilt when that file
# changes, even without a `changed`: `def` follows the declaration the file's
# new content selects, not the one in the NIF written before.

import ns2slurp

discard text()

discard """
$nimsuggest2 $file
!copy fixtures/mns2slurp.nim ns2slurp.nim
!copy fixtures/mns2slurped_v1.txt ns2slurped.txt
>changed $file
>def $file:7:9
def;;skProc;;ns2slurp.text;;proc (): string{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2slurp.nim;;3;;7;;""
!copy fixtures/mns2slurped_v2.txt ns2slurped.txt
>def $file:7:9
def;;skProc;;ns2slurp.text;;proc (): string{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2slurp.nim;;5;;7;;""
!del ns2slurp.nim
!del ns2slurped.txt
"""
