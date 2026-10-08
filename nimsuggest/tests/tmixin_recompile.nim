import fixtures/mmixinfoo

proc foo(x: int): int = 1

static: doAssert callFoo(1) == foo(1)

proc bar(): int = 0#[!]#

# `callFoo[int]` is instantiated here and binds this module's `foo`. After the
# edit changes `foo`, the recompilation must not reuse that instance: it would
# still call the old `foo`.
discard """
$nimsuggest --tester --v4 $file
>chk $1
chk;;skUnknown;;;;Hint;;$file;;7;;5;;"\'bar\' is declared but not used [XDeclaredButNotUsed]";;0
chk;;skUnknown;;;;Hint;;???;;0;;-1;;"> (toplevel): import: system.nim [Processing]";;0
!edit 'int = 1' 'int = 2'
>chk $1
chk;;skUnknown;;;;Hint;;$file;;7;;5;;"\'bar\' is declared but not used [XDeclaredButNotUsed]";;0
chk;;skUnknown;;;;Hint;;???;;0;;-1;;"> (toplevel): import: system.nim [Processing]";;0
"""
