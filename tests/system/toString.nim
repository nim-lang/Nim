discard """
  output:'''@[23, 45]
@[, foo, bar]
{a, b, c}
2.3242
2.982
123912.1
123912.1823
5.0
1e+100
inf
-inf
nan
nil
nil
"""

echo($(@[23, 45]))
echo($(@["", "foo", "bar"]))
#echo($(["", "foo", "bar"]))
#echo($([23, 45]))
# bug #2395

let alphaSet: set[char] = {'a'..'c'}
echo alphaSet

echo($(2.3242))
echo($(2.982))
echo($(123912.1))
echo($(123912.1823))
echo($(5.0))
echo($(1e100))
echo($(1e1000000))
echo($(-1e1000000))
echo($(0.0/0.0))

# nil tests
var x: seq[string]
var y: string
echo(x)
echo(y)

type
  Foo = object
    a: int
    b: string

var foo1: Foo

doAssert $foo1 == "(a: 0, b: nil)"

const
  data = @['a','b', '\0', 'c','d']
  dataStr = $data

# ensure same result when on VM or when at program execution
doAssert dataStr == $data

import strutils
# array test
let arr = ['H','e','l','l','o',' ','W','o','r','l','d','!','\0']

# not sure if this is really a good idea
doAssert startsWith($arr, "[H, e, l, l, o,  , W, o, r, l, d, !,")
doAssert $arr.cstring == "Hello World!"
