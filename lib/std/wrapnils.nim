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
    x3: ref int

  var f: Foo
  assert ?.f.x2.x1 == "" # returns default value since `f` is nil

  var f2 = Foo(x1: "a")
  f2.x2 = f2
  assert ?.f2.x1 == "a" # same as f2.x1 (no nil LHS in this chain)
  assert ?.Foo(x1: "a").x1 == "a" # can use constructor inside

  # when you know a sub-expression is not nil, you can scope it as follows:
  assert ?.(f2.x2.x2).x3[] == 0 # because `f` is nil

type Wrapnil[T] = object
  valueImpl: T
  validImpl: bool

proc wrapnil[T](a: T): Wrapnil[T] =
  ## See top-level example.
  Wrapnil[T](valueImpl: a, validImpl: true)

template unwrap(a: Wrapnil): untyped =
  ## See top-level example.
  a.valueImpl

{.push experimental: "dotOperators".}

template `.`*(a: Wrapnil, b): untyped =
  ## See top-level example.
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

proc isValid(a: Wrapnil): bool =
  ## Returns true if `a` didn't contain intermediate `nil` values (note that
  ## `a.valueImpl` itself can be nil even in that case)
  a.validImpl

template `[]`*[I](a: Wrapnil, i: I): untyped =
  ## See top-level example.
  let a1 = a # to avoid double evaluations
  if a1.validImpl:
    # correctly will raise IndexDefect if a is valid but wraps an empty container
    wrapnil(a1.valueImpl[i])
  else:
    default(Wrapnil[type(a1.valueImpl[i])])

template `[]`*(a: Wrapnil): untyped =
  ## See top-level example.
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

import std/macros

proc replace(n: NimNode): NimNode =
  if n.kind == nnkPar:
    doAssert n.len == 1
    newCall(bindSym"wrapnil", n[0])
  elif n.kind in {nnkCall, nnkObjConstr}:
    newCall(bindSym"wrapnil", n)
  elif n.len == 0:
    newCall(bindSym"wrapnil", n)
  else:
    n[0] = replace(n[0])
    n

macro `?.`*(a: untyped): untyped =
  ## Transforms `a` into an expression that can be safely evaluated even in
  ## presence of intermediate nil pointers/references, in which case a default
  ## value is produced.
  #[
  Using a template like this wouldn't work:
    template `?.`*(a: untyped): untyped = wrapnil(a)[]
  ]#
  result = replace(a)
  result = quote do:
    `result`.valueImpl
