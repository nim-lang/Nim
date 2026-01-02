discard """
  targets: "c cpp"
"""
# Test const initialization of objects with opaque importc fields (e.g. FILE from stdio.h)

type OpaqueFile {.importc: "FILE", header: "<stdio.h>".} = object

type
  SimpleStruct = object
    normal: int
    opaque: OpaqueFile

  NestedStruct = object
    inner: SimpleStruct
    value: float

  VariantStruct = object
    case kind: bool
    of true:
      opaque: OpaqueFile
    of false:
      normal: int

  ArrayElementStruct = object
    id: int
    atom: OpaqueFile

const simple = default(SimpleStruct)
const nested = default(NestedStruct)
const variant = default(VariantStruct)
const arr = default(array[3, ArrayElementStruct])

static:
  doAssert simple.normal == 0
  doAssert nested.value == 0.0
  doAssert arr[0].id == 0

# completeStruct types use normal aggregate init
type CompleteImportc {.importc: "int", completeStruct, nodecl.} = object
  value: cint

type StructWithComplete = object
  c: CompleteImportc
  x: int

const withComplete = default(StructWithComplete)

type TupleWithOpaque = tuple[x: int, s: SimpleStruct, y: float]
const tupleVal = default(TupleWithOpaque)

# Sandwich: opaque between non-opaque fields requires designated init
type SandwichStruct = object
  first: int
  opaque: OpaqueFile
  last: float

const sandwich = default(SandwichStruct)

static:
  doAssert withComplete.x == 0
  doAssert tupleVal.x == 0
  doAssert sandwich.first == 0
  doAssert sandwich.last == 0.0

proc useSimple(s: ptr SimpleStruct) {.exportc, noinline.} = discard
proc useNested(s: ptr NestedStruct) {.exportc, noinline.} = discard
proc useArr(a: ptr array[3, ArrayElementStruct]) {.exportc, noinline.} = discard
proc useComplete(s: ptr StructWithComplete) {.exportc, noinline.} = discard
proc useVariant(v: ptr VariantStruct) {.exportc, noinline.} = discard
proc useTuple(t: TupleWithOpaque) {.exportc, noinline.} = discard
proc useSandwich(s: ptr SandwichStruct) {.exportc, noinline.} = discard

useSimple(simple.addr)
useNested(nested.addr)
useArr(arr.addr)
useComplete(withComplete.addr)
useVariant(variant.addr)
useTuple(tupleVal)
useSandwich(sandwich.addr)

# Edge cases: different C/Nim names
type OpaqueWithCName {.importc: "FILE", header: "<stdio.h>".} = object

type StructWithRenamedField = object
  nimName {.importc: "c_name".}: int
  opaque: OpaqueWithCName

const renamedField = default(StructWithRenamedField)
proc useRenamedField(s: ptr StructWithRenamedField) {.exportc, noinline.} = discard
useRenamedField(renamedField.addr)
static: doAssert renamedField.nimName == 0

type NimTypeName {.importc: "int", completeStruct, nodecl.} = distinct cint

type StructContainingRenamedType = object
  inner: NimTypeName
  opaque: OpaqueFile

const withRenamedType = default(StructContainingRenamedType)
proc useRenamedType(s: ptr StructContainingRenamedType) {.exportc, noinline.} = discard
useRenamedType(withRenamedType.addr)

type StructWithExportedField = object
  nimField {.exportc: "exported_field".}: int
  opaque: OpaqueFile

const withExported = default(StructWithExportedField)
proc useExportedField(s: ptr StructWithExportedField) {.exportc, noinline.} = discard
useExportedField(withExported.addr)
static: doAssert withExported.nimField == 0

type ByCopyStruct {.bycopy.} = object
  data: int
  opaque: OpaqueFile

const byCopyVal = default(ByCopyStruct)
proc useByCopy(s: ByCopyStruct) {.exportc, noinline.} = discard
useByCopy(byCopyVal)
static: doAssert byCopyVal.data == 0

type PackedStruct {.packed.} = object
  a: int8
  opaque: OpaqueFile
  b: int8

const packedVal = default(PackedStruct)
proc usePacked(s: ptr PackedStruct) {.exportc, noinline.} = discard
usePacked(packedVal.addr)
static:
  doAssert packedVal.a == 0
  doAssert packedVal.b == 0

type UnionWithOpaque {.union.} = object
  intVal: int
  opaque: OpaqueFile

const unionVal = default(UnionWithOpaque)
proc useUnion(u: ptr UnionWithOpaque) {.exportc, noinline.} = discard
useUnion(unionVal.addr)

# Deep nesting
type DeepLevel1 = object
  field1: int
  opaque: OpaqueFile

type DeepLevel2 = object
  nested: DeepLevel1
  field2: float

type DeepLevel3 = object
  deep: DeepLevel2
  field3: int
  opaque2: OpaqueWithCName

const deepVal = default(DeepLevel3)
proc useDeep(d: ptr DeepLevel3) {.exportc, noinline.} = discard
useDeep(deepVal.addr)
static:
  doAssert deepVal.deep.nested.field1 == 0
  doAssert deepVal.deep.field2 == 0.0
  doAssert deepVal.field3 == 0

# Multiple opaque fields with renamed non-opaque fields
type MultiOpaque = object
  first {.importc: "first_field".}: int
  opaque1: OpaqueFile
  second {.importc: "second_field".}: float
  opaque2: OpaqueWithCName
  third: int

const multiOpaque = default(MultiOpaque)
proc useMultiOpaque(m: ptr MultiOpaque) {.exportc, noinline.} = discard
useMultiOpaque(multiOpaque.addr)

static:
  doAssert multiOpaque.first == 0
  doAssert multiOpaque.second == 0.0
  doAssert multiOpaque.third == 0
