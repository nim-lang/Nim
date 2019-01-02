# note: not merging with tests/assert/testhelper.nim as this pulls less
# dependencies so is more generally applicable

proc assertEquals*[T](lhs: T, rhs: T) =
  ## Simplified version of `unittest.require` that satisfies a common use case,
  ## while avoiding pulling too many dependencies. The `{}` are useful to
  ## spot whitespace issues.
  if lhs!=rhs:
    echo "lhs:{\n", lhs, "}\nrhs:{\n", rhs, "}"
    doAssert false
