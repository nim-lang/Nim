discard """
    action: "compile"
    targets: "cpp"
    cmd: "nim cpp $file"
"""

# see #21505: ensure compilation of imported C++ objects with explicit constructors while retaining default initialization through codegen changes due to #21279

{.emit:"""/*TYPESECTION*/

struct ExplObj
{
  explicit ExplObj(int bar = 0) {}  
};

struct BareObj
{
    BareObj() {}
};

""".}

type
  ExplObj {.importcpp.} = object
  BareObj {.importcpp.} = object

type
  Composer = object
    explObj: ExplObj
    bareObj: BareObj

proc foo =
  var composer1 {.used.}: Composer
  let composer2 {.used.} = Composer()

var composer1 {.used.}: Composer
let composer2 {.used.} = Composer()

foo()