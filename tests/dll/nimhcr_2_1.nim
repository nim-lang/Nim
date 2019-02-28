
import hotcodereloading

type
  Type2 = ref object of RootObj
    data*: int

let g_2* = @[Type2(data: 2), Type2(data: 3)][1..^1] # should have a length of 1

var a: tuple[str: string, i: int]
a.str = "   2: random string"
echo a.str

beforeCodeReload:
  echo "   2: before!"
