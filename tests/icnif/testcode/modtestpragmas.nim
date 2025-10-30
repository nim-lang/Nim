var exportcTest {.exportc.}: int
var importcTest {.importc.}: int
var y* {.importc, header: "test.h".}: int
var EACCES {.importc, nodecl.}: cint
var volatileTest {.volatile.}: int

const FooBar {.intdefine.}: int = 5
echo FooBar

{.passc: "-Wall -Werror".}
{.link: "myfile.o".}

type
  TestImportC {.importc.} = object
    x: int

  TestImportC2 {.importc: "TestImportC2Name".} = object
    x {.importc.}: int
    y {.importc: "yyy".}: int

  TestBitfield = object
    flag {.bitsize:1.}: cuint

  TestEnumWithSize* {.size: sizeof(uint32).} = enum
    X,
    Y,
    Z

  sseType = object
    sseData {.align(16).}: array[4, float32]

  TestUnionObj {.union.} = object
    x: cint
    y: cfloat

const irr = "<irrlicht/irrlicht.h>"
type
  IrrlichtDeviceObj {.header: irr,
                      importcpp: "irr::IrrlichtDevice".} = object

proc importCProc() {.importc.}
proc importCProc2(x: cint) {.importc: "import_c_proc_2".}
proc headerProc(): cint {.importc, header: "foo.h".}

proc exportCProc() {.exportc.}

{.pragma: pragmaPragmaTest, importc, header: "foo.h".}
proc pragmaPragmaTestProc() {.pragmaPragmaTest.}
