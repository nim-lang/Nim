discard """
  targets: "cpp"
  cmd: "nim cpp $file"
"""

{.emit:"""/*TYPESECTION*/
struct CppClass {
  int x;
  int y;
  CppClass(int inX, int inY) {
    this->x = inX;
    this->y = inY;
  }
  //CppClass() = default;
};
""".}

type  CppClass* {.importcpp.} = object
  x: int32
  y: int32

proc makeCppClass(x, y: int32): CppClass {.importcpp: "CppClass(@)", constructor.}

var shouldCompile = makeCppClass(1, 2)
