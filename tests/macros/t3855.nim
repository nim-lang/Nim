discard """
  nimout: '''
top foo
inner foo
top 123
inner 123
inner untyped: x + 1
'''
"""

# bug #3855: inner procs of macros capturing the macro's params
macro foo(a: static[string]) =
  echo "top ", a
  proc bar() =
    echo "inner ", a
  bar()

foo("foo")

macro foo2(a: static[int]) =
  echo "top ", a
  proc bar() =
    echo "inner ", a
  bar()

foo2(123)

macro foo3(n: untyped) =
  proc bar() =
    echo "inner untyped: ", n.repr
  bar()

foo3(x + 1)
