# A failed `nim ns` run must not report the modules it did not rebuild as
# checked: `ns2shrink` drops most of itself, including `extra1`, so this file
# fails to compile there and keeps its NIF, which refers to symbols of the old
# `ns2shrink`. Loading it crashed `chk` with "symbol has no offset": the
# one-shot answered nothing instead of the errors.

import ns2shrink

let thing = makeThing(1)
echo thing.x
echo extra1().f1

discard """
$nimsuggest2 $file
!copy fixtures/mns2shrink_v1.nim ns2shrink.nim
>changed $file
!copy fixtures/mns2shrink_v2.nim ns2shrink.nim
>chk $file:0:0
chk;;skUnknown;;;;Error;;$file;;11;;5;;*
!del ns2shrink.nim
"""
