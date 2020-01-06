## This module allows chains of field-access and indexing where the LHS can be nil.
## This simplifies code by reducing need for if-else branches around intermediate values
## that maybe be nil.
##
## Note: experimental module and relies on {.experimental: "dotOperators".}
## Unstable API.

runnableExamples:
  type Foo = ref object
    x1: string
    x2: Foo
  var f: Foo
  assert f.wrapnil.x2.x1[] == ""
  assert Foo(x1: "a").wrapnil.x1[] == "a"

type Wrapnil*[T] = object
  valueImpl*: T

proc wrapnil*[T](a: T): Wrapnil[T] =
  Wrapnil[T](valueImpl: a)

{.push experimental: "dotOperators".}

template `.`*(a: Wrapnil, b): untyped =
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
  a.valueImpl

template `[]`*[I](a: Wrapnil, i: I): untyped =
  let a2 = a.valueImpl # to avoid double evaluations
  if len(a2) == 0:
    wrapnil(default(type(a2[i])))
  else:
    wrapnil(a2[i])
