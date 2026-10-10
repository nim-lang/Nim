import fixtures/mbox

type Foo = object
  x: int

var b: Box[Foo]
echo b.v.x

proc bar(): int = 0#[!]#

# `Box[Foo]` is instantiated while compiling this module but cached under `Box`,
# which belongs to another module. `chkFile` with a dirty buffer recompiles only
# this module; the new `Foo` gets the id the old one had, so a kept instance
# matches it and still holds the old `Foo`, without the field `y`.
discard """
$nimsuggest --tester --v4 $file
>chkFile $1
chk;;skUnknown;;;;Hint;;$file;;9;;5;;"\'bar\' is declared but not used [XDeclaredButNotUsed]";;0
!edit 'x: int' 'x, y: int'
!edit 'echo b.v.x' 'echo b.v.y'
>chkFile $1
chk;;skUnknown;;;;Hint;;$file;;9;;5;;"\'bar\' is declared but not used [XDeclaredButNotUsed]";;0
"""
