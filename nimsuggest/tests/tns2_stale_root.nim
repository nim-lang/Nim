# A failed `nim ns` run (an extra root that never builds) must not report the
# modules it did not rebuild as checked: this file's NIF refers to symbols of the
# old `ns2shrink`, and loading it crashed `chk` with "symbol has no offset": the
# one-shot answered nothing. The hints `chk` answers with come first.

import ns2shrink

let thing = makeThing(1)
echo thing.x

discard """
$nimsuggest2 $file
!copy fixtures/mns2shrink_v1.nim ns2shrink.nim
!copy fixtures/mns2broken.nim ns2broken.nim
>changed $file
>def $path/ns2broken.nim:2:8
!copy fixtures/mns2shrink_v2.nim ns2shrink.nim
>chk $file:0:0
chk;;skUnknown;;;;Hint;;*
!del ns2shrink.nim
!del ns2broken.nim
"""
