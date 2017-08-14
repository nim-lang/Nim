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
'''
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

proc bar(arg: cstring): void =
  doAssert arg[0] == '\0'

proc baz(arg: openarray[char]): void =
  doAssert arg.len == 0

proc stringCompare(): void =
  var a,b,c,d,e,f,g: string
  a.add 'a'
  b.add "bee"
  c.add 123.456
  doAssert a == "a"
  doAssert b == "bee"
  b.add g
  doAssert b == "bee"
  doAssert c == "123.456"

  var h = ""
  var i = ""
  doAssert d == ""
  doAssert "" == e
  doAssert f == g
  doAssert "" == ""
  doAssert h == ""
  doAssert "" == h
  doAssert nil == i
  doAssert i == nil

  g.setLen(10)
  doAssert g == "\0\0\0\0\0\0\0\0\0\0"
  doAssert "" != "\0\0\0\0\0\0\0\0\0\0"

  var nilstring: string
  bar(nilstring)
  baz(nilstring)

stringCompare()
