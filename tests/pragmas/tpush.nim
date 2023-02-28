# test the new pragmas

{.push warnings: off, hints: off.}
proc noWarning() =
  var
    x: int
  echo(x)

{.pop.}

proc WarnMe() =
  var
    x: int
  echo(x)

# bug #11852
proc foo(x: string, y: int, res: int) =
  {.push checks: off}
  var a: ptr char = unsafeAddr(x[y])
  {.pop.}
  if x.len > y:
    doAssert ord(a[]) == 51
  else:
    doAssert x.len + 48 == res

foo("", 0, 48)
foo("abc", 40, 51)
