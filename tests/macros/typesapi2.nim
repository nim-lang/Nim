# tests to see if a symbol returned from macros.getType() can
# be used as a type
import macros

macro testTypesym (t:typed): untyped =
    var ty = t.getType
    if ty.typekind == ntyTypedesc:
        # skip typedesc get to the real type
        ty = ty[1].getType

    if ty.kind == nnkSym: return ty
    assert ty.kind == nnkBracketExpr
    assert ty[0].kind == nnkSym
    result = ty[0]
    return

type TestFN = proc(a,b:int):int
var iii: testTypesym(TestFN)
static: assert iii is TestFN

proc foo11 : testTypesym(void) =
    echo "HI!"
static: assert foo11 is (proc():void {.nimcall.})

var sss: testTypesym(seq[int])
static: assert sss is seq[int]
# very nice :>

static: assert array[2,int] is testTypesym(array[2,int])
static: assert(ref int is testTypesym(ref int))
static: assert(void is testTypesym(void))


macro tts2 (t:typed, idx:int): untyped =
    var ty = t.getType
    if ty.typekind == ntyTypedesc:
        # skip typedesc get to the real type
        ty = ty[1].getType

    if ty.kind == nnkSym: return ty
    assert ty.kind == nnkBracketExpr
    return ty[idx.intval.int]
type TestFN2 = proc(a:int,b:float):string
static:
    assert(tts2(TestFN2, 0) is TestFN2)
    assert(tts2(TestFN2, 1) is string)
    assert(tts2(TestFN2, 2) is int)
    assert(tts2(TestFN2, 3) is float)
