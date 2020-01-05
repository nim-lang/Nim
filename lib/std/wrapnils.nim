type Wrapnil*[T] = object
  valueImpl*: T

proc wrapnil*[T](a: T): Wrapnil[T] =
  ## Allows chains of field-access and indexing where the LHS can be nil.
  ## This simplifies code by reducing need for if-else branches around intermediate
  ## maybe nil values.
  ## Note: experimental module and relies on {.experimental: "dotOperators".}
  runnableExamples:
    type Foo = ref object
      x1: string
      x2: Foo
    var f: Foo
    assert f.wrapnil.x2.x1[] == ""
  Wrapnil[T](valueImpl: a)

{.push experimental: "dotOperators".}

template `.`*(a: Wrapnil, b): untyped =
  ## See `wrapnil`
  let a2 = a.valueImpl # to avoid double evaluations
  when type(a2) is ref|ptr:
    if a2 == nil:
      wrapnil(default(type(a2.b)))
    else:
      wrapnil(a2.b)
  else:
    wrapnil(a2.b)

{.pop.}

template `[]`*(a: Wrapnil): untyped =
  ## See `wrapnil`
  a.valueImpl

template `[]`*[I](a: Wrapnil, i: I): untyped =
  ## See `wrapnil`
  let a2 = a.valueImpl # to avoid double evaluations
  if len(a2) == 0:
    wrapnil(default(type(a2[i])))
  else:
    wrapnil(a2[i])
