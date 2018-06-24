{.emit: """/*TYPESECTION*/
template<int X>
struct T { int check = X; };
""".}

type
  T* {.importcpp: "T", noDecl.} [N: static[int]] = object
    check: int

var x: T[128]
assert x.check == 128
