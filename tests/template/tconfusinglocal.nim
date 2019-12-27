discard """
output: "0"
"""


# bug #5135
proc fail*[E](e: E): void =
  raise newException(Exception, e)

# bug #4875
type Bar = object
    mFoo: int

template foo(a: Bar): int = a.mFoo

proc main =
    let foo = 5 # Rename this to smth else to make it work
    var b: Bar
    echo b.foo

main()
