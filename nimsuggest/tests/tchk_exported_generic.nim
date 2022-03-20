# test we get some suggestion at the end of the file

# Test for #19371
type BinaryTree[T] = object

proc add*[T](this: BinaryTree[T]) = discard
proc doOtherThing[T](this: BinaryTree[T]) = discard

add(BinaryTree[string]())
doOtherThing(BinaryTree[string]())


#[!]#
discard """
$nimsuggest --tester $file
>chk $1
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">> (toplevel): import(dirty): tests/tchk_exported_generic.nim [Processing]";;0
"""
