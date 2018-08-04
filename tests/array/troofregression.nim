###############################
#### part from Arraymancer

type
  MetadataArray* = object
    data*: array[8, int]
    len*: int

# Commenting the converter removes the error "lib/system.nim(3536, 3) Error: for a 'var' type a variable needs to be passed"
converter toMetadataArray*(se: varargs[int]): MetadataArray {.inline.} =
  result.len = se.len
  for i in 0..<se.len:
    result.data[i] = se[i]


when NimVersion >= "0.17.3":
  type Index = int or BackwardsIndex
  template `^^`(s, i: untyped): untyped =
    when i is BackwardsIndex:
      s.len - int(i)
    else: i
else:
  type Index = int
  template `^^`(s, i: untyped): untyped =
    i

## With Nim devel from the start of the week (~Oct30) I managed to trigger "lib/system.nim(3536, 4) Error: expression has no address"
## but I can't anymore after updating Nim (Nov5)
## Now commenting this plain compiles and removes the error "lib/system.nim(3536, 3) Error: for a 'var' type a variable needs to be passed"
proc `[]`*(a: var MetadataArray, idx: Index): var int {.inline.} =
  a.data[a ^^ idx]


##############################
### Completely unrelated lib that triggers the issue

type
  MySeq[T] = ref object
    data: seq[T]

proc test[T](sx: MySeq[T]) =
  # Removing the backward index removes the error "lib/system.nim(3536, 3) Error: for a 'var' type a variable needs to be passed"
  echo sx.data[^1] # error here

let s = MySeq[int](data: @[1, 2, 3])
s.test()
