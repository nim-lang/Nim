# One query per command nimsuggest2's one-shot answers; `changed` builds the
# NIFs first. On saved code without a dirty file, `def`/`use`/`dus`/`highlight`
# come from the NIFs; the rest compile this file.

import mns2lib

proc double(x: int): int =
  let y = twice(x)
  y

proc unused(s: string) = discard

let b = boxed(2)
discard double(b.value)
discard double(b.#[!]#value)
discard double(#[!]#b.value)

discard """
$nimsuggest2 $file
>changed $file
>project $file
$file
>known $file
true
>def $file:14:9
def;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;7;;5;;""
>declaration $file:14:9
declaration;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;7;;5;;""
>use $file:14:9
def;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;7;;5;;""
use;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;14;;8;;""
use;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;15;;8;;""
use;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;16;;8;;""
>dus $file:14:9
def;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;7;;5;;""
use;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;14;;8;;""
use;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;15;;8;;""
use;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;16;;8;;""
>highlight $file:8:6
def;;skLet;;tns2_commands.double.y;;int;;$file;;8;;6;;""
use;;skLet;;tns2_commands.double.y;;int;;$file;;9;;2;;""
>type $file:13:4
type;;skType;;mns2lib.Box;;Box;;*mns2lib.nim;;2;;2;;""
>sug $1
sug;;skField;;value;;int;;*mns2lib.nim;;3;;4;;""
>con $2
con;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;7;;5;;""
>expand $file:8:10
expand;;skUnknown;;;;;;;;8;;10;;"x + x";;0;;8;;18
>outline2 $file:1:0
outline;;skProc;;tns2_commands.double;;;;$file;;7;;5;;""
outline;;skProc;;tns2_commands.unused;;;;$file;;11;;5;;""
>globalSymbols double
def;;skProc;;tns2_commands.double;;proc (x: int): int{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;7;;5;;""
>chkFile $file;$file:0:0
chk;;skUnknown;;;;Hint;;$file;;11;;5;;"\'unused\' is declared but not used [XDeclaredButNotUsed]";;0
>chk $file:0:0
chk;;skUnknown;;;;Hint;;$file;;11;;5;;"\'unused\' is declared but not used [XDeclaredButNotUsed]";;0
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">> (toplevel): import(dirty): tests/tns2_commands.nim [Processing]";;0
>recompile
>quit
"""
