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
# Should give a type-mismatch since Something isn't a valid Test
b[0].name = "Test" #[tt.Error
            ^  type mismatch]#
