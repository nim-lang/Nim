discard """
output: '''baz
10
100
1000
a
b
c
x: 1, y: test 1
x: 2, y: test 2
x: 10, y: test 3
x: 4, y: test 4
'''
"""

type
  Foo = object
    x: int

proc stringVarargs*(strings: varargs[string, `$`]): void =
  for s in strings: echo s

proc fooVarargs*(foos: varargs[Foo]) =
  for f in foos: echo f.x

template templateForwarding*(callable: untyped,
                             condition: bool,
                             forwarded: varargs[untyped]): untyped =
  if condition:
    callable(forwarded)

proc procForwarding(args: varargs[string]) =
  stringVarargs(args)

templateForwarding stringVarargs, 17 + 4 < 21, "foo", "bar", 100
templateForwarding stringVarargs, 10 < 21, "baz"

templateForwarding fooVarargs, "test".len > 3, Foo(x: 10), Foo(x: 100), Foo(x: 1000)

procForwarding "a", "b", "c"

proc hasKeywordArgs(x = 10, y = "y") =
  echo "x: ", x, ", y: ", y

proc hasRegularArgs(x: int, y: string) =
  echo "x: ", x, ", y: ", y

templateForwarding(hasRegularArgs, true, 1, "test 1")
templateForwarding hasKeywordArgs, true, 2, "test 2"

templateForwarding(hasKeywordArgs, true, y = "test 3")
templateForwarding hasKeywordArgs, true, y = "test 4", x = 4

