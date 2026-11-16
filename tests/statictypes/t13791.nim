discard """
  targets: "c js"
  output: '''
1
2
3
6
'''
"""

# bug #13791: a `static` parameter of an inline iterator
type
  Foo = object
    s: seq[int]
func makeFoo(s: seq[int]): Foo =
  result.s = s
iterator fooIt(foo: static Foo): int {.inline.} =
  for x in foo.s:
    yield x
iterator times(n: static int; f: int): int {.inline.} =
  for i in 1..n: yield i*f
proc main() =
  for x in fooIt(makeFoo(@[1, 2])):
    echo x
  for x in times(2, 3):
    echo x
main()
