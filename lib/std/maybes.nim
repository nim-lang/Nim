type Maybe*[T] = object
  valueImpl*: T

proc maybe*[T](a: T): auto =
  ## Allows chains of field-access and indexing where the LHS can be nil.
  ## This simplifies code by reducing need for if-else branches around intermediate
  ## maybe nil values.
  runnableExamples:
    type Foo = ref object
      x1: string
      x2: Foo
    var f: Foo
    assert f.maybe.x2.x1[] == ""
  Maybe[T](valueImpl: a)

template `.`*(a: Maybe, b): untyped =
  let a2 = a.valueImpl # to avoid double evaluations
  when a2 is ref|ptr:
    if a2 == nil:
      maybe(default(type(a2.b)))
    else:
      maybe(a2.b)
  else:
    maybe(a2.b)

template `[]`*(a: Maybe): untyped =
  a.valueImpl

template `[]`*[I](a: Maybe, i: I): untyped =
  let a2 = a.valueImpl # to avoid double evaluations
  if len(a2) == 0:
    maybe(default(type(a2[i])))
  else:
    maybe(a2[i])
