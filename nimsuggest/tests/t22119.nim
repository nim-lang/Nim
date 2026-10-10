import std/strformat

type Vector[T] = object
  len: int
  # for convenience. Practically this will be doing its own allocations
  data: seq[T]

proc `[]`*[T](x: Vector[T]; i: Natural): lent T =
  result = x.data[i]

proc `[]=`*[T](x: var Vector[T]; i: Natural; y: T) =
  x.data[i] = y

proc setLen*[T](x: var Vector[T]; len: int; init: T = default(T)) =
  x.len = len
  x.data.setLen(len)

type StorageType[T] =
  # chk doesn't crash if we use seq instead of Vector
  # seq[T]
  Vector[T]

type State* = object
  storagePtr: ptr[StorageType[int]]

proc testme*(state: var State) =
  let idx = state.storagePtr[].len
  state.storagePtr[].setLen(idx+1)
  state.storagePtr[][idx] = 1 # chk doesn't crash when commenting out this line

var state: State
var storage: StorageType[int]
state.storagePtr = storage.addr
testme(state)
echo fmt"{state.storagePtr[][0]=}"

proc foo(): int = 1#[!]#

{.warning: "end".}

# bug #22119: after a recompilation, the cached instances of the previous
# compilation made `setLen` a type mismatch and nimsuggest crashed. The warning
# on the last line comes after any error in the module.
discard """
$nimsuggest --tester $file
>chk $1
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">> (toplevel): import(dirty): tests/t22119.nim [Processing]";;0
chk;;skUnknown;;;;Warning;;$file;;39;;9;;"end [User]";;0
!edit 'int = 1' 'int = 2'
>chk $1
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">>> (toplevel): import(dirty): tests/t22119.nim [Processing]";;0
chk;;skUnknown;;;;Warning;;$file;;39;;9;;"end [User]";;0
"""
