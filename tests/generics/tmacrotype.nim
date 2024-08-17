discard """
  # XXX not actually fixed
  disabled: true # cannot instantiate: 'T'
  # the use of `typedesc` delays the macro unlike `typed` or `untyped`
  # but this makes it impossible for overloading to infer the type
  # some code depends on `typedesc` needing to be resolved, e.g. tmacrogenerics
  # so we can't change it, but maybe we can add a version of `typedesc` that allows generic params
  # maybe something like `typed{typedesc}` so it doesn't lift to a generic param
"""

import std/[sequtils, macros]

block: # issue #23432
  type
    Future[T] = object
    InternalRaisesFuture[T, E] = object

  macro Raising[T](F: typedesc[Future[T]], E: varargs[typedesc]): untyped =
    ## Given a Future type instance, return a type storing `{.raises.}`
    ## information
    ##
    ## Note; this type may change in the future
    E.expectKind(nnkBracket)

    let raises = nnkTupleConstr.newTree(E.mapIt(it))
    nnkBracketExpr.newTree(
      ident "InternalRaisesFuture",
      nnkDotExpr.newTree(F, ident"T"),
      raises
    )

  type X[E] = Future[void].Raising(E)

  proc f(x: X) = discard


  var v: Future[void].Raising([ValueError])
  f(v)
