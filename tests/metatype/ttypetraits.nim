import typetraits
import macros

block: # isNamedTuple
  type Foo1 = (a:1,).type
  type Foo2 = (Field0:1,).type
  type Foo3 = ().type
  type Foo4 = object

  doAssert (a:1,).type.isNamedTuple
  doAssert Foo1.isNamedTuple
  doAssert Foo2.isNamedTuple
  doAssert isNamedTuple(tuple[key: int])
  doAssert not Foo3.isNamedTuple
  doAssert not Foo4.isNamedTuple
  doAssert not (1,).type.isNamedTuple

proc typeToString*(t: typedesc, prefer = "preferTypeName"): string {.magic: "TypeTrait".}
  ## Returns the name of the given type, with more flexibility than `name`,
  ## and avoiding the potential clash with a variable named `name`.
  ## prefer = "preferResolved" will resolve type aliases recursively.
  # Move to typetraits.nim once api stabilized.

block: # typeToString
  type MyInt = int
  type
    C[T0, T1] = object
  type C2=C # alias => will resolve as C
  type C2b=C # alias => will resolve as C (recursively)
  type C3[U,V] = C[V,U]
  type C4[X] = C[X,X]
  template name2(T): string = typeToString(T, "preferResolved")
  doAssert MyInt.name2 == "int"
  doAssert C3[MyInt, C2b].name2 == "C3[int, C]"
    # C3 doesn't get resolved to C, not an alias (nor does C4)
  doAssert C2b[MyInt, C4[cstring]].name2 == "C[int, C4[cstring]]"
  doAssert C4[MyInt].name2 == "C4[int]"
  when BiggestFloat is float and cint is int:
    doAssert C2b[cint, BiggestFloat].name2 == "C3[int, C3[float, int32]]"

  template name3(T): string = typeToString(T, "preferMixed")
  doAssert MyInt.name3 == "MyInt{int}"
  doAssert (tuple[a: MyInt, b: float]).name3 == "tuple[a: MyInt{int}, b: float]"
  doAssert (tuple[a: C2b[MyInt, C4[cstring]], b: cint, c: float]).name3 ==
    "tuple[a: C2b{C}[MyInt{int}, C4[cstring]], b: cint{int32}, c: float]"

block distinctBase:
  block:
    type
      Foo[T] = distinct seq[T]
    var a: Foo[int]
    doAssert a.type.distinctBase is seq[int]

  block:
    # simplified from https://github.com/nim-lang/Nim/pull/8531#issuecomment-410436458
    macro uintImpl(bits: static[int]): untyped =
      if bits >= 128:
        let inner = getAST(uintImpl(bits div 2))
        result = newTree(nnkBracketExpr, ident("UintImpl"), inner)
      else:
        result = ident("uint64")

    type
      BaseUint = UintImpl or SomeUnsignedInt
      UintImpl[Baseuint] = object
      Uint[bits: static[int]] = distinct uintImpl(bits)

    doAssert Uint[128].distinctBase is UintImpl[uint64]

    block:
      type
        AA = distinct seq[int]
        BB = distinct string
        CC = distinct int
        AAA = AA

      static:
        var a2: AAA
        var b2: BB
        var c2: CC

        doAssert(a2 is distinct)
        doAssert(b2 is distinct)
        doAssert(c2 is distinct)

        doAssert($distinctBase(typeof(a2)) == "seq[int]")
        doAssert($distinctBase(typeof(b2)) == "string")
        doAssert($distinctBase(typeof(c2)) == "int")

block genericParams:
  type Foo[T1, T2]=object
  doAssert genericParams(Foo[float, string]) is (float, string)
  type Foo1 = Foo[float, int]
  doAssert genericParams(Foo1) is (float, int)
  type Foo2 = Foo[float, Foo1]
  doAssert genericParams(Foo2) is (float, Foo[float, int])
  doAssert genericParams(Foo2) is (float, Foo1)
  doAssert genericParams(Foo2).get(1) is Foo1
  doAssert (int,).get(0) is int
  doAssert (int, float).get(1) is float
  static: doAssert (int, float).lenTuple == 2
  static: doAssert (1, ).lenTuple == 1
  static: doAssert ().lenTuple == 0


##############################################
# bug 13095

type
  CpuStorage{.shallow.}[T] = ref object
    when supportsCopyMem(T):
      raw_buffer*: ptr UncheckedArray[T] # 8 bytes
      memalloc*: pointer                 # 8 bytes
      isMemOwner*: bool                  # 1 byte
    else: # Tensors of strings, other ref types or non-trivial destructors
      raw_buffer*: seq[T]                # 8 bytes (16 for seq v2 backed by destructors?)

var x = CpuStorage[string]()

static:
  doAssert(not string.supportsCopyMem)
  doAssert x.T is string          # true
  doAssert x.raw_buffer is seq