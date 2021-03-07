discard """
  targets: "cpp"
"""

type
  Map[T,U] {.importcpp: "std::map", header: "<map>".} = object

proc cInitMap(T: typedesc, U: typedesc): Map[T,U] {.importcpp: "std::map<'*1,'*2>()", nodecl.}

proc initMap[T, U](): Map[T, U] =
  result = cInitMap(T, U)

var x: Map[cstring, cint] = initMap[cstring, cint]()
