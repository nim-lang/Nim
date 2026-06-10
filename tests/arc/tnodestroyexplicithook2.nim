discard """
  output: '''
246
246
'''
"""

# issue #25730

type
  Inner[T] = object
    x: T
  Foo[T] = object
    inner: Inner[T]
  Bar[T] = object
    foo: Foo[T]

proc `=sink`[T](a: var Inner[T], b: Inner[T]) {.nodestroy.} =
  a.x = b.x * 2

proc `=copy`[T](a: var Inner[T], b: Inner[T]) {.nodestroy.} =
  a.x = b.x * 2

when true:
  proc `=sink`[T](a: var Bar[T], b: Bar[T]) {.nodestroy.} =
    `=sink`(a.foo, b.foo)

  proc `=copy`[T](a: var Bar[T], b: Bar[T]) {.nodestroy.} =
    `=copy`(a.foo, b.foo)

proc useSink() =
  let a = Bar[int](foo: Foo[int](inner: Inner[int](x: 123)))
  var b: Bar[int]
  `=sink`(b, a)
  echo b.foo.inner.x

useSink()

proc useCopy() =
  let a = Bar[int](foo: Foo[int](inner: Inner[int](x: 123)))
  var b: Bar[int]
  `=copy`(b, a)
  echo b.foo.inner.x

useCopy()
