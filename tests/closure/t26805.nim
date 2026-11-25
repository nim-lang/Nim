discard """
  matrix: "--mm:refc; --mm:orc; --mm:arc"
"""

# bug #26805: `for x in getAll()` inside a routine nested in the closure
# iterator's owner created the iterator's environment without initializing
# its `:up` field (the reference to the enclosing routine's env): the
# for-loop desugar runs while the inner routine's body is transformed for
# the detection pass, where the lambda lift is a no-op. Depending on the
# surroundings this either emitted C referencing an undeclared `args_p0`
# (the iterator's body itself was never lifted) or segfaulted at runtime
# dereferencing the nil `:up` field.

proc outer(args: seq[string]) =
  iterator getAll(): string =
    for arg in args:
      yield arg

  proc getFirst(): string =
    for value in getAll():
      return value

  # Needed to trigger the bad codegen path in the original report: without
  # this loop, the compiler emitted C referencing undeclared `args_p0`.
  for value in getAll():
    discard

  doAssert getFirst() == "a"

outer(@["a"])

# sibling form: no direct use of the iterator in `outer` at all; the
# iterator body was left referencing the owner's parameter `args`
proc outer2(args: seq[string]) =
  iterator getAll(): string =
    for arg in args:
      yield arg

  proc getFirst(): string =
    for value in getAll():
      return value

  doAssert getFirst() == "b"

outer2(@["b"])

# sibling form: `for x in getAll()` inside the iterator's own owner, with
# the owner itself nested in another routine
proc outer3() =
  proc outer(args: seq[string]) =
    iterator getAll(): string =
      for arg in args:
        yield arg
    var seen: seq[string]
    for v in getAll():
      seen.add v
    doAssert seen == @["c"]

  outer(@["c"])

outer3()

# sibling form: a for-loop over a capturing iterator nested in an iterator
proc outer4(args: seq[string]) =
  iterator wrap(): string =
    iterator getAll(): string =
      for a in args:
        yield a
    for v in getAll():
      yield v

  var seen: seq[string]
  for v in wrap():
    seen.add v
  doAssert seen == @["d"]

outer4(@["d"])
