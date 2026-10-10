type A = object
  x: int

proc `=destroy`(a: A) = discard

proc foo(): int = 1#[!]#

# The hooks bound to the previous compilation's types must be dropped when
# the module is recompiled, otherwise binding `=destroy` again fails with
# "cannot bind another '=destroy' to: A".
discard """
$nimsuggest --tester --v4 $file
>chk $1
chk;;skUnknown;;;;Hint;;$file;;6;;5;;"\'foo\' is declared but not used [XDeclaredButNotUsed]";;0
!edit 'int = 1' 'int = 2'
>chk $1
chk;;skUnknown;;;;Hint;;$file;;6;;5;;"\'foo\' is declared but not used [XDeclaredButNotUsed]";;0
"""
