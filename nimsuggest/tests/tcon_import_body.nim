# An import recompiled while answering a query in another file keeps its proc
# bodies: only the bodies in the queried file are skipped.

import micbody

discard compute()

discard """
!copy fixtures/micbody_v1.nim micbody.nim
$nimsuggest --v3 --tester $file
>con $file:6:16
con;;skProc;;micbody.compute;;proc (): int*;;*micbody.nim;;1;;5;;"";;100
!copy fixtures/micbody_v2.nim micbody.nim
>changed $path/micbody.nim
>con $file:6:16
con;;skProc;;micbody.compute;;proc (): int*;;*micbody.nim;;1;;5;;"";;100
!del micbody.nim
"""
