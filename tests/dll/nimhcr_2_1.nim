
import hotcodereloading

type
  Type2 = ref object of RootObj
    data*: int

let g_2* = @[Type2(data: 2), Type2(data: 3)][1..^1] # should have a length of 1

const c_2* = [1, 2, 3] # testing that a complext const object is properly exported

var a: tuple[str: string, i: int]
a.str = "   2: random string"
echo a.str

beforeCodeReload:
  echo "   2: before!"

# testing a construct of 2 functions in the same module which reference each other
# https://github.com/nim-lang/Nim/issues/11608
proc rec_1(depth: int)
proc rec_2(depth: int) =
  rec_1(depth + 1)
proc rec_1(depth: int) =
  if depth < 3:
    rec_2(depth)
  else:
    echo("max mutual recursion reached!")

# https://github.com/nim-lang/Nim/issues/11996
let rec_2_func_ref = rec_2
rec_2_func_ref(0)
