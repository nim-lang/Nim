# nimsuggest2 makes a file the project does not import one more root of
# `nim ns` the first time a query names it: its imports become known, it is
# answered from its NIF like a project module (`highlight` lists the definition
# once), and the next `changed` builds it again.

discard """
$nimsuggest2 $file
!copy fixtures/mns2outside.nim ns2outside.nim
!copy fixtures/mns2outsidedep.nim ns2outsidedep.nim
>changed $file
>known $path/ns2outside.nim
false
>highlight $path/ns2outside.nim:3:6
def;;skProc;;ns2outside.greet;;proc (): string{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2outside.nim;;3;;5;;""
use;;skProc;;ns2outside.greet;;proc (): string{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2outside.nim;;5;;8;;""
>known $path/ns2outsidedep.nim
true
>highlight $path/ns2outside.nim:3:6
def;;skProc;;ns2outside.greet;;proc (): string{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2outside.nim;;3;;5;;""
use;;skProc;;ns2outside.greet;;proc (): string{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2outside.nim;;5;;8;;""
>changed $file
>known $path/ns2outside.nim
true
!del ns2outside.nim
!del ns2outsidedep.nim
"""
