discard """
  targets: "cpp"
  cmd: "nim cpp $file"
  output: "3"
"""

{.emit:"""/*TYPESECTION*/
  int operate(int x, int y, int (*func)(const int&, const int&)){
    return func(x, y);
  };
""".}

proc operate(x, y: int32, fn: proc(x, y: int32 ): int32 {.cdecl.}): int32 {.importcpp:"$1(@)".}

proc add(a {.codegenDecl:"const $#& $#".}, b {.codegenDecl:"const $# $#", byref.}: int32): int32  {.cdecl.} = a + b

echo operate(1, 2, add)