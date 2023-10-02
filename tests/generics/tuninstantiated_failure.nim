discard """
cmd: "nim check $file"
"""

type
  Test[T, K] = object
    name: string
  Something = Test[int]

func `[]`[T, K](x: var Test[T, K], idx: int): var Test[T, K] =
  x

var b: Something
# Should give an error since Something isn't a valid Test
b[0].name = "Test" #[tt.Error
 ^  expression '' has no type (or is ambiguous)]#
