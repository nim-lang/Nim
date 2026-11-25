# `use` on an overload of a module compiled from source finds its uses in the
# other modules' NIFs by the overload's NIF name, not by its compiled one: the
# dirty buffer adds an overload before the saved ones, so it numbers them
# differently from the NIF (`ovl.0` is the `int` overload there, the `string`
# one here). Without the mapping the `int` overload lists the `float` call and
# the new `string` overload lists the `int` call.

import mns2ovllib

discard ovl(1)
discard ovl(1.0)

discard """
$nimsuggest2 $file
>changed $file
>use $path/mns2ovllib.nim;$path/fixtures/mns2ovllib_dirty.nim:2:6
def;;skProc;;mns2ovllib.ovl;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;*/mns2ovllib.nim;;2;;5;;""
use;;skProc;;mns2ovllib.ovl;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;10;;8;;""
>use $path/mns2ovllib.nim;$path/fixtures/mns2ovllib_dirty.nim:1:6
def;;skProc;;mns2ovllib.ovl;;proc (x: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;*/mns2ovllib.nim;;1;;5;;""
>use $path/mns2ovllib.nim;$path/fixtures/mns2ovllib_dirty.nim:3:6
def;;skProc;;mns2ovllib.ovl;;proc (x: float): float{.noSideEffect, gcsafe, raises: <inferred> [].};;*/mns2ovllib.nim;;3;;5;;""
use;;skProc;;mns2ovllib.ovl;;proc (x: float): float{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;11;;8;;""
"""
