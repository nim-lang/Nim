# Every project file nimsuggest2 is started with is built with its own config,
# and a query uses the config of the project that reaches the file it names:
# `mns2projall` imports `mns2projlib` through the search path its folder's
# `nim.cfg` adds, which this project's config does not have. A file no project
# reaches uses the config of the project in the innermost folder holding it.

discard """
$nimsuggest2 $file $path/ns2projects/tests/mns2projall.nim
>changed $file
>known $path/ns2projects/tests/mns2projall.nim
true
>def $path/ns2projects/tests/mns2projall.nim:3:9
def;;skProc;;mns2projlib.fromLib;;proc (): int{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2projects/mns2projlib.nim;;1;;5;;""
>project $path/ns2projects/tests/mns2projall.nim
*/ns2projects/tests/mns2projall.nim
>chk $path/ns2projects/tests/mns2projall.nim:0:0
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">> (toplevel): import(dirty): tests/mns2projall.nim [Processing]";;0
!copy fixtures/mns2projnew.nim ns2projects/tests/ns2projnew.nim
>def $path/ns2projects/tests/ns2projnew.nim:3:9
def;;skProc;;mns2projlib.fromLib;;proc (): int{.noSideEffect, gcsafe, raises: <inferred> [].};;*/ns2projects/mns2projlib.nim;;1;;5;;""
>project $path/ns2projects/tests/ns2projnew.nim
*/ns2projects/tests/mns2projall.nim
>project $path/fixtures/mns2projnew.nim
*/tns2_projects.nim
!del ns2projects/tests/ns2projnew.nim
"""
