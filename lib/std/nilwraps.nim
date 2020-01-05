type Nilwrap*[T] = object
  valueImpl*: T

proc nilwrap*[T](a: T): auto =
  ## Allows chains of field-access and indexing where the LHS can be nil.
  ## This simplifies code by reducing need for if-else branches around intermediate
  ## maybe nil values.
  runnableExamples:
    type Foo = ref object
      x1: string
      x2: Foo
    var f: Foo
    assert f.nilwrap.x2.x1[] == ""
  Nilwrap[T](valueImpl: a)

{.push experimental: "dotOperators".}

template `.`*(a: Nilwrap, b): untyped =
  ## See `nilwrap`
  let a2 = a.valueImpl # to avoid double evaluations
  when type(a2) is ref|ptr:
    if a2 == nil:
      nilwrap(default(type(a2.b)))
    else:
      nilwrap(a2.b)
  else:
    nilwrap(a2.b)

{.pop.}

template `[]`*(a: Nilwrap): untyped =
  ## See `nilwrap`
  a.valueImpl

template `[]`*[I](a: Nilwrap, i: I): untyped =
  ## See `nilwrap`
  let a2 = a.valueImpl # to avoid double evaluations
  if len(a2) == 0:
    nilwrap(default(type(a2[i])))
  else:
    nilwrap(a2[i])
