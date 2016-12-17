discard """
  cmd: "nim cpp $file"
  output: '''6.0'''
"""

# bug #4730

type Vector* {.importcpp: "std::vector", header: "<vector>".}[T] = object

template `[]=`*[T](v: var Vector[T], key: int, val: T) =
  {.emit: [v, "[", key, "] = ", val, ";"].}

proc setLen*[T](v: var Vector[T]; size: int) {.importcpp: "resize", nodecl.}
proc `[]`*[T](v: var Vector[T], key: int): T {.importcpp: "(#[#])", nodecl.}

proc main =
  var v: Vector[float]
  v.setLen 1
  v[0] = 6.0
  echo v[0]

main()
