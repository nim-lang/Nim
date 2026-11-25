# `use` also lists the uses in the modules that only another project builds,
# read from that project's NIFs: only the project in `ns2projects/tests`
# builds `mns2projall`. The second `use` names a dirty file, so it is answered
# by compiling instead of from the NIFs.

import ns2projects/mns2projlib

discard fromLib()

discard """
$nimsuggest2 $file $path/ns2projects/tests/mns2projall.nim
>changed
>use $file:8:9
def;;skProc;;mns2projlib.fromLib;;proc (): int{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2projects/mns2projlib.nim;;1;;5;;""
use;;skProc;;mns2projlib.fromLib;;proc (): int{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2projects/tests/mns2projall.nim;;3;;8;;""
use;;skProc;;mns2projlib.fromLib;;proc (): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;8;;8;;""
>use $file;$file:8:9
def;;skProc;;mns2projlib.fromLib;;proc (): int{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2projects/mns2projlib.nim;;1;;5;;""
use;;skProc;;mns2projlib.fromLib;;proc (): int{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2projects/tests/mns2projall.nim;;3;;8;;""
use;;skProc;;mns2projlib.fromLib;;proc (): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;8;;8;;""
"""
