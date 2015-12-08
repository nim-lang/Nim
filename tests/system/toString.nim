discard """
  file: "toString.nim"
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
nil'''
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
