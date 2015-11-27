discard """
  output: '''123
1234
123
1234
12345
'''
"""

# Test simple type
var a = 123
proc getA(): var int = a

echo getA()

getA() = 1234
echo getA()


# Test object type
type Foo = object
    a: int
var f: Foo
f.a = 123
proc getF(): var Foo = f
echo getF().a
getF().a = 1234
echo getF().a
getF() = Foo(a: 12345)
echo getF().a
