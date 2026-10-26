# A NIF is stale when the body of an import it ran at compile time changed after
# it was written, even if that import's interface did not. The failed `nim ns`
# run (an extra root that never builds) rebuilds `qzdimpl` with a new body of
# `depValue` but not `qzmimpl`, which ran it: `highlight` must not answer from
# the NIFs (two results) but compile (the def twice).

import qzmimpl

proc shout(s: string): string = s & "!"

discard shout($midValue)

discard """
$nimsuggest2 $file
!copy fixtures/mns2implgen_v1.nim qzdimpl.nim
!copy fixtures/mns2implmid.nim qzmimpl.nim
!copy fixtures/mns2broken.nim ns2broken.nim
>changed $file
>def $path/ns2broken.nim:2:8
!copy fixtures/mns2implgen_v2.nim qzdimpl.nim
>highlight $file:11:9
def;;skProc;;tns2_stale_impl.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;9;;5;;""
def;;skProc;;tns2_stale_impl.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;9;;5;;""
use;;skProc;;tns2_stale_impl.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;11;;8;;""
!del qzdimpl.nim
!del qzmimpl.nim
!del ns2broken.nim
"""
