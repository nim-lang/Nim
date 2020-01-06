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
  valueImpl: T
  validImpl: bool

proc wrapnil*[T](a: T): Wrapnil[T] =
  Wrapnil[T](valueImpl: a, validImpl: true)

{.push experimental: "dotOperators".}

template `.`*(a: Wrapnil, b): untyped =
  let a1 = a # to avoid double evaluations
  let a2 = a1.valueImpl
  type T = Wrapnil[type(a2.b)]
  if a1.validImpl:
    when type(a2) is ref|ptr:
      if a2 == nil:
        default(T)
      else:
        wrapnil(a2.b)
    else:
      wrapnil(a2.b)
  else:
    # nil is "sticky"; this is needed, see tests
    default(T)

{.pop.}

template `[]`*(a: Wrapnil): untyped =
  a.valueImpl

proc isNotNil*(a: Wrapnil): bool = a.validImpl

template `[]`*[I](a: Wrapnil, i: I): untyped =
  let a1 = a # to avoid double evaluations
  if a1.validImpl:
    # correctly will raise IndexError if a is valid but wraps an empty container
    wrapnil(a1.valueImpl[i])
  else:
    default(Wrapnil[type(a1.valueImpl[i])])

template deref*(a: Wrapnil): untyped =
  ## Since `[]` is hijacked, we can use `deref` that wraps original `system.[]`
  let a1 = a # to avoid double evaluations
  let a2 = a1.valueImpl
  type T = Wrapnil[type(a2[])]
  if a1.validImpl:
    if a2 == nil:
      default(T)
    else:
      wrapnil(a2[])
  else:
    default(T)
