## This module allows chains of field-access and indexing where the LHS can be nil.
## This simplifies code by reducing need for if-else branches around intermediate values
## that may be nil.
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

from std/options import Option, isSome, get, option, unsafeGet, UnpackDefect
export options.get, options.isSome, options.isNone

template fakeDot*(a: Option, b): untyped =
  ## See top-level example.
  let a1 = a # to avoid double evaluations
  type T = Option[typeof(unsafeGet(a1).b)]
  if isSome(a1):
    let a2 = unsafeGet(a1)
    when typeof(a2) is ref|ptr:
      if a2 == nil:
        default(T)
      else:
        option(a2.b)
    else:
      option(a2.b)
  else:
    # nil is "sticky"; this is needed, see tests
    default(T)

# xxx this should but doesn't work: func `[]`*[T, I](a: Option[T], i: I): Option {.inline.} =

func `[]`*[T, I](a: Option[T], i: I): auto {.inline.} =
  ## See top-level example.
  if isSome(a):
    # correctly will raise IndexDefect if a is valid but wraps an empty container
    result = option(a.unsafeGet[i])

func `[]`*[U](a: Option[U]): auto {.inline.} =
  ## See top-level example.
  if isSome(a):
    let a2 = a.unsafeGet
    if a2 != nil:
      result = option(a2[])

import std/macros

func replace(n: NimNode): NimNode =
  if n.kind == nnkDotExpr:
    result = newCall(bindSym"fakeDot", replace(n[0]), n[1])
  elif n.kind == nnkPar:
    doAssert n.len == 1
    result = newCall(bindSym"option", n[0])
  elif n.kind in {nnkCall, nnkObjConstr}:
    result = newCall(bindSym"option", n)
  elif n.len == 0:
    result = newCall(bindSym"option", n)
  else:
    n[0] = replace(n[0])
    result = n

proc safeGet[T](a: Option[T]): T {.inline.} =
  get(a, default(T))

macro `?.`*(a: untyped): auto =
  ## Transforms `a` into an expression that can be safely evaluated even in
  ## presence of intermediate nil pointers/references, in which case a default
  ## value is produced.
  result = replace(a)
  result = quote do:
    # `result`.val # TODO: expose a way to do this directly in std/options, e.g.: `getAsIs`
    safeGet(`result`)

macro `??.`*(a: untyped): Option =
  ## Same as `?.` but returns an `Option`.
  runnableExamples:
    type Foo = ref object
      x1: ref int
      x2: int
    # `?.` can't distinguish between a valid vs invalid default value, but `??.` can:
    var f1 = Foo(x1: int.new, x2: 2)
    doAssert (??.f1.x1[]).get == 0 # not enough to tell when the chain was valid.
    doAssert (??.f1.x1[]).isSome # a nil didn't occur in the chain
    doAssert (??.f1.x2).get == 2

    var f2: Foo
    doAssert not (??.f2.x1[]).isSome # f2 was nil
    from std/options import UnpackDefect
    doAssertRaises(UnpackDefect): discard (??.f2.x1[]).get
    doAssert ?.f2.x1[] == 0 # in contrast, this returns default(int)

  result = replace(a)
