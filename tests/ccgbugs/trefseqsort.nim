discard """
  output: '''@[0, 4, 9, 1, 3, 2]
@[0, 1, 2, 3, 9]'''
"""
# bug #6724
import algorithm

type
  Bar = object
    bar: ref seq[int]
  Foo = ref Bar

proc test(x: ref Foo) =
  x.bar[].del(1)
  x.bar[].sort(cmp)

proc main() =
  var foo: ref Foo
  new(foo)

  var s = @[0, 4, 9, 1, 3, 2]

  var sr: ref seq[int]
  new(sr)
  sr[] = s

  foo[] = Foo(bar: sr)
  echo($foo.bar[])

  test(foo)
  echo($foo.bar[])

main()
