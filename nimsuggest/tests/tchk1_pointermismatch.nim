type BinaryTree*[T] = ref object
  left, right: BinaryTree[T]
  data: T

proc newNode*[T](data: T): BinaryTree[T] =
  new(result)
  result.data = data

proc add*[T](this: var BinaryTree[T], n: BinaryTree[T]) =
  discard

type
  MyBase = ref object of RootObj
  MyChild = ref object of MyBase

method doThing(base: MyBase) {.base.} = discard
method doThing(base: MyChild) = discard

# instantiate a BinaryTree with `string`
var root: BinaryTree[string]
# instantiates `newNode` and `add`
root.add(newNode("hello"))


#[!]#
discard """
$nimsuggest --tester $file
>chk $1
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">> (toplevel): import(dirty): tests/tchk1_pointermismatch.nim [Processing]";;0
"""
