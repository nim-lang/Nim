# tests to see if a symbol returned from macros.getType() can
# be used as a type
import macros

macro testTypesym (t:stmt): expr =
    var ty = t.getType
    if ty.typekind == ntyTypedesc:
        # skip typedesc get to the real type
        ty = ty[1].getType

    if ty.kind == nnkSym: return ty
    doAssert ty.kind == nnkBracketExpr
    doAssert ty[0].kind == nnkSym
    result = ty[0]
    return

type TestFN = proc(a,b:int):int
var iii: testTypesym(TestFN)
static: doAssert iii is TestFN

proc foo11 : testTypesym(void) =
    echo "HI!"
static: doAssert foo11 is (proc():void {.nimcall.})

var sss: testTypesym(seq[int])
static: doAssert sss is seq[int]
# very nice :>

static: doAssert array[2,int] is testTypesym(array[2,int])
static: doAssert(ref int is testTypesym(ref int))
static: doAssert(void is testTypesym(void))


macro tts2 (t:stmt, idx:int): expr =
    var ty = t.getType
    if ty.typekind == ntyTypedesc:
        # skip typedesc get to the real type
        ty = ty[1].getType

    if ty.kind == nnkSym: return ty
    doAssert ty.kind == nnkBracketExpr
    return ty[idx.intval.int]
type TestFN2 = proc(a:int,b:float):string
static:
    doAssert(tts2(TestFN2, 0) is TestFN2)
    doAssert(tts2(TestFN2, 1) is string)
    doAssert(tts2(TestFN2, 2) is int)
    doAssert(tts2(TestFN2, 3) is float)
