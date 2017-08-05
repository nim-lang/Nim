discard """
  cmd: "nim -d:testdef $target $file"
  output: '''works 34
34
defined
first impl'''
"""

{.reorder: on.}

{.push callconv: stdcall.}
proc bar(x: T)

proc foo() =
  bar(34)
  whendep()

proc foo(dummy: int) = echo dummy

proc bar(x: T) =
  echo "works ", x
  foo(x)

foo()

type
  T = int

when defined(testdef):
  proc whendep() = echo "defined"
else:
  proc whendep() = echo "undefined"

when not declared(goo):
  proc goo() = echo "first impl"

when not declared(goo):
  proc goo() = echo "second impl"

goo()

{.pop.}
