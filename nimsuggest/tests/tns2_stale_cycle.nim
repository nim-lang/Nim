# The members of an import cycle are written by one `nim m`, one after the
# other: after a change to the interfaces of both `qzacycle` and `qzbcycle`,
# which import each other, the member written first has a NIF older than the
# other's interface cookie. That does not make it stale: `highlight` answers
# from the NIFs (two results, not the def twice of a compile).

import qzacycle

proc shout(s: string): string = s & "!"

discard shout(a())

discard """
$nimsuggest2 $file
!copy fixtures/mns2cyclea.nim qzacycle.nim
!copy fixtures/mns2cycleb.nim qzbcycle.nim
>changed $file
!copy fixtures/mns2cyclea_v2.nim qzacycle.nim
!copy fixtures/mns2cycleb_v2.nim qzbcycle.nim
>highlight $file:11:9
def;;skProc;;tns2_stale_cycle.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;9;;5;;""
use;;skProc;;tns2_stale_cycle.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;11;;8;;""
!del qzacycle.nim
!del qzbcycle.nim
"""
