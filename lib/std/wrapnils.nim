## This module allows chains of field-access and indexing where the LHS can be nil.
## This simplifies code by reducing need for if-else branches around intermediate values
## that maybe be nil.
##
## Note: experimental module, unstable API.

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

  # when you know a sub-expression doesn't involve a `nil` (e.g. `f2.x2.x2`),
  # you can scope it as follows:
  assert ?.(f2.x2.x2).x3[] == 0

  assert (?.f2.x2.x2).x3 == nil  # this terminates ?. early
  import segfaults # enable `NilAccessDefect` exceptions
  doAssertRaises(NilAccessDefect): echo (?.f2.x2.x2).x3[]

type Wrapnil[T] = object
  valueImpl: T
  validImpl: bool

template wrapnil[T](a: T): Wrapnil[T] =
  ## See top-level example.
  Wrapnil[T](valueImpl: a, validImpl: true)

template get*[T](a: Wrapnil[T]): T =
  ## See top-level example.
  a.valueImpl

proc isSome*(a: Wrapnil): bool {.inline.} =
  ## Returns true if `a` didn't contain intermediate `nil` values (note that
  ## `a.valueImpl` itself can be nil even in that case)
  a.validImpl

template fakeDot*(a: Wrapnil, b): untyped =
  ## See top-level example.
  let a1 = a # to avoid double evaluations
  let a2 = a1.valueImpl
  type T = Wrapnil[typeof(a2.b)]
  if a1.validImpl:
    when typeof(a2) is ref|ptr:
      if a2 == nil:
        default(T)
      else:
        wrapnil(a2.b)
    else:
      wrapnil(a2.b)
  else:
    # nil is "sticky"; this is needed, see tests
    default(T)

template `[]`*[I](a: Wrapnil, i: I): untyped =
  ## See top-level example.
  let a1 = a # to avoid double evaluations
  if a1.validImpl:
    # correctly will raise IndexDefect if a is valid but wraps an empty container
    wrapnil(a1.valueImpl[i])
  else:
    default(Wrapnil[typeof(a1.valueImpl[i])])

template `[]`*(a: Wrapnil): untyped =
  ## See top-level example.
  let a1 = a # to avoid double evaluations
  let a2 = a1.valueImpl
  type T = Wrapnil[typeof(a2[])]
  if a1.validImpl:
    if a2 == nil:
      default(T)
    else:
      wrapnil(a2[])
  else:
    default(T)

import std/macros

proc replace(n: NimNode): NimNode =
  if n.kind == nnkDotExpr:
    result = newCall(bindSym"fakeDot", replace(n[0]), n[1])
  elif n.kind == nnkPar:
    doAssert n.len == 1
    result = newCall(bindSym"wrapnil", n[0])
  elif n.kind in {nnkCall, nnkObjConstr}:
    result = newCall(bindSym"wrapnil", n)
  elif n.len == 0:
    result = newCall(bindSym"wrapnil", n)
  else:
    n[0] = replace(n[0])
    result = n

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

macro `??.`*(a: untyped): untyped =
  ## Same as `?.` but returns an option-like object that can be unboxed with `get`.
  ## or checked for validity with `isSome`.
  runnableExamples:
    type Foo = ref object
      x1: ref int
      x2: int
    # ?. can't distinguish between a valid vs invalid default value, but `??.` can:
    var f1 = Foo(x1: int.new, x2: 2)
    doAssert ??.f1.x1[].get == 0 # not enough to tell when the chain was valid.
    doAssert ??.f1.x1[].isSome # a nil didn't occur in the chain
    doAssert ??.f2.x2.get == 2

    var f2: Foo
    doAssert not ??.f2.x1[].isSome # f2 was nil

  result = replace(a)
