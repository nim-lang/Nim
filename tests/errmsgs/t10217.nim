discard """
  cmd: "nim check $file"
  action: "reject"
  errormsg: "expression 'v1' has no type (or is ambiguous)"
"""

# bug #10217; `nim check` crashed on a malformed generic type
type
    Vector*  {.importcpp: "std::vector", header: "vector".}[T] = object

proc initVector*[T](n: csize): Vector[T]
    {.importcpp: "std::vector<'*0>(@)", header: "vector".}

var v1 = initVector[int](10)
var v2 : Vector[int]

v1 = v2
