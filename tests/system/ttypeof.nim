static: doAssert typeof(1) is int

func isVar[T](x: var T): bool = true
func isVar[T](x: T): bool = false

proc testVarParams1(a: var int;
                    b: typeof(a);
                    c: typeof(a, typeOfIter);
                    d: typeof(a, typeOfIter, typeOfModCompatible);
                    e: typeof(a, typeOfIter, typeOfModRemoveModifier);
                    f: typeof(a, typeOfIter, typeOfModKeepModifier);
                    g: typeof(a, modifierMode = typeOfModCompatible);
                    h: typeof(a, modifierMode = typeOfModRemoveModifier);
                    i: typeof(a, modifierMode = typeOfModKeepModifier);
                    ) =
  doAssert not isVar(b)
  doAssert not isVar(c)
  doAssert not isVar(d)
  doAssert not isVar(e)
  doAssert isVar(f)
  doAssert not isVar(g)
  doAssert not isVar(h)
  doAssert isVar(i)

static: doAssert testVarParams1 is proc (a: var int; b: int; c: int; d: int; e: int; f: var int; g: int; h: int; i: var int) {.nimcall.}

block:
  var a, f, i: int
  testVarParams1(a, 0, 0, 0, 0, f, 0, 0, i)

proc testVarParams2(a: var proc(x: var int): var int;
                    b: typeof(a);
                    c: typeof(a, modifierMode = typeOfModKeepModifier)) =
  doAssert not isVar(b)
  doAssert isVar(c)

static: doAssert testVarParams2 is proc (a: var proc(x: var int): var int; b: proc(x: var int): var int; c: var proc(x: var int): var int) {.nimcall.}

proc testRet(a: var int): typeof(a) = 0
static: doAssert testRet is proc (a: var int): int {.nimcall.}
proc testRet2(a: var int): typeof(a, modifierMode = typeOfModCompatible) = 0
static: doAssert testRet2 is proc (a: var int): int {.nimcall.}
proc testRet3(a: var int): typeof(a, modifierMode = typeOfModRemoveModifier) = 0
static: doAssert testRet3 is proc (a: var int): int {.nimcall.}
#proc testRet4(a: var int): typeof(a, modifierMode = typeOfModKeepModifier) = a
#static: doAssert testRet4 is proc (a: var int): var int {.nimcall.}

proc fooSink1(a: sink string;
              b: typeof(a);
              c: typeof(a, modifierMode = typeOfModRemoveModifier);
              d: typeof(a, modifierMode = typeOfModKeepModifier)) = discard

static: doAssert fooSink1 is proc (a: sink string; b: sink string; c: string; d: sink string) {.nimcall.}

proc fooLentRet(a: seq[string]): lent string = a[0]
proc testLentRetComp(a: seq[string]): typeof(fooLentRet(a), modifierMode = typeOfModCompatible) = a[0]
proc testLentRetRemo(a: seq[string]): typeof(fooLentRet(a), modifierMode = typeOfModRemoveModifier) = a[0]
proc testLentRetKeep(a: seq[string]): typeof(fooLentRet(a), modifierMode = typeOfModKeepModifier) = a[0]

static:
  doAssert testLentRetComp is proc (a: seq[string]): string {.nimcall.}
  doAssert testLentRetRemo is proc (a: seq[string]): string {.nimcall.}
  #doAssert testLentRetKeep is proc (a: seq[string]): lent string {.nimcall.}
