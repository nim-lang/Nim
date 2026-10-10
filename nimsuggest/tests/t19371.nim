type BinaryTree*[T] = ref object
  left, right: BinaryTree[T]
  data: T

proc newNode*[T](data: T): BinaryTree[T] =
  new(result)
  result.data = data

proc add*[T](this: var BinaryTree[T], n: BinaryTree[T]) =
  discard

when isMainModule:
  # instantiate a BinaryTree with `string`
  var root: BinaryTree[string]
  # instantiates `newNode` and `add`
  root.add(newNode("hello"))

proc foo(): int = 1#[!]#

{.warning: "end".}

# bug #19371: after a recompilation, the cached instances of the previous
# compilation made `add` a type mismatch. The warning on the last line comes
# after any error in the module.
discard """
$nimsuggest --tester $file
>chk $1
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">> (toplevel): import(dirty): tests/t19371.nim [Processing]";;0
chk;;skUnknown;;;;Warning;;$file;;20;;9;;"end [User]";;0
!edit 'int = 1' 'int = 2'
>chk $1
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">>> (toplevel): import(dirty): tests/t19371.nim [Processing]";;0
chk;;skUnknown;;;;Warning;;$file;;20;;9;;"end [User]";;0
"""
