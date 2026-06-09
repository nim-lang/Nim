static: doAssert typeof(1) is int

func isVar[T](x: var T): bool = true
func isVar[T](x: T): bool = false

proc testVarParams1(a: var int;
                    b: typeof(a);
                    c: typeof(a, typeOfIter);
                    d: typeof(a, typeOfIter, CompatibleTypeModifiers);
                    e: typeof(a, typeOfIter, RemoveTypeModifiers);
                    f: typeof(a, typeOfIter, KeepTypeModifiers);
                    g: typeof(a, modifierMode = CompatibleTypeModifiers);
                    h: typeof(a, modifierMode = RemoveTypeModifiers);
                    i: typeof(a, modifierMode = KeepTypeModifiers);
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

# `CompatibleTypeModifiers` and `RemoveTypeModifiers` remove only top `var`, not `var` inside proc type
proc testVarParams2(a: var proc(x: var int): var int;
                    b: typeof(a);
                    c: typeof(a, modifierMode = CompatibleTypeModifiers);
                    d: typeof(a, modifierMode = RemoveTypeModifiers);
                    e: typeof(a, modifierMode = KeepTypeModifiers)) =
  doAssert not isVar(b)
  doAssert not isVar(c)
  doAssert not isVar(d)
  doAssert isVar(e)

static: doAssert testVarParams2 is proc (a: var proc(x: var int): var int;
                                         b: proc(x: var int): var int;
                                         c: proc(x: var int): var int;
                                         d: proc(x: var int): var int;
                                         e: var proc(x: var int): var int) {.nimcall.}

block:
  var a, e: proc(x: var int): var int = nil
  let b, c, d: proc(x: var int): var int = nil
  testVarParams2(a, b, c, d, e)

proc testRet(a: var int): typeof(a) = 0
static: doAssert testRet is proc (a: var int): int {.nimcall.}
proc testRet2(a: var int): typeof(a, modifierMode = CompatibleTypeModifiers) = 0
static: doAssert testRet2 is proc (a: var int): int {.nimcall.}
proc testRet3(a: var int): typeof(a, modifierMode = RemoveTypeModifiers) = 0
static: doAssert testRet3 is proc (a: var int): int {.nimcall.}

proc fooSink1(a: sink string;
              b: typeof(a);
              c: typeof(a, modifierMode = CompatibleTypeModifiers);
              d: typeof(a, modifierMode = RemoveTypeModifiers);
              e: typeof(a, modifierMode = KeepTypeModifiers)) = discard

static: doAssert fooSink1 is proc (a: sink string; b: sink string; c: sink string; d: string; e: sink string) {.nimcall.}

proc fooLentRet(a: seq[string]): lent string = a[0]
proc testLentRetComp(a: seq[string]): typeof(fooLentRet(a), modifierMode = CompatibleTypeModifiers) = a[0]
proc testLentRetRemo(a: seq[string]): typeof(fooLentRet(a), modifierMode = RemoveTypeModifiers) = a[0]
proc testLentRetKeep(a: seq[string]): typeof(fooLentRet(a), modifierMode = KeepTypeModifiers) = a[0]

# workaround # issue 25830
proc dummyLentProc(a: seq[string]): lent string = a[0]

static:
  doAssert testLentRetComp is proc (a: seq[string]): string {.nimcall.}
  doAssert testLentRetRemo is proc (a: seq[string]): string {.nimcall.}
  doAssert testLentRetKeep is typeof(dummyLentProc)

proc voidProc() = discard
static:
  doAssert typeof(voidProc()) is void

type
  Foo = typeof(Bar)
  Bar = int

static:
  doAssert Foo is int
