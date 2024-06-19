discard """
  targets: "c js"
"""

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

# bug #22362
{.push staticBoundChecks: on.}
proc main(): void =
  {.pop.}
  discard
  {.push staticBoundChecks: on.}

main()


{.push exportC.}

block:
  proc foo11() =
    const factor = [1, 2, 3, 4]
    doAssert factor[0] == 1
  proc foo21() =
    const factor = [1, 2, 3, 4]
    doAssert factor[0] == 1

  foo11()
  foo21()

template foo31() =
  let factor = [1, 2, 3, 4]
  doAssert factor[0] == 1
template foo41() =
  let factor = [1, 2, 3, 4]
  doAssert factor[0] == 1

foo31()
foo41()

{.pop.}
