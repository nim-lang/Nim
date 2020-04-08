## tests for addAbiCheck (via NIM_STATIC_ASSERT)

{.emit:"""
struct Foo1{
  int a;
};
struct Foo2{
  int a;
};
enum Foo3{k1, k2};
typedef enum Foo3 Foo3b;
typedef enum Foo4{k3, k4} Foo4;

typedef int Foo5[3];

typedef struct Foo6{
  int a1;
  bool a2;
  double a3;
  struct Foo6* a4;
} Foo6;
""".}

block:
  type Foo1Alias{.importc: "struct Foo1", size: sizeof(cint).} = object
    a: cint
  ## ensures cgen
  discard Foo1Alias.default

block:
  type Foo3Alias{.importc: "enum Foo3", size: sizeof(cint).} = enum
    k1, k2
  discard Foo3Alias.default

block:
  type Foo3bAlias{.importc: "Foo3b", size: sizeof(cint).} = enum
    k1, k2
  discard Foo3bAlias.default

block:
  type Foo3b{.importc, size: sizeof(cint).} = enum
    k1, k2
  discard Foo3b.default
  static:
    doAssert Foo3b.sizeof == cint.sizeof

block:
  type Foo4{.importc, size: sizeof(cint).} = enum
    k3, k4
  # adding entries should not yield duplicate ABI checks, as enforced by
  # `typeABICache`.
  # Currently the test doesn't check for this but you can inspect the cgen'd file
  discard Foo4.default
  discard Foo4.default
  discard Foo4.default

block:
  type Foo5{.importc.} = array[3, cint]
  discard Foo5.default

block:
  type Foo5{.importc.} = array[3, cint]
  discard Foo5.default

block: # CT sizeof
  type Foo6Groundtruth = object
    a1: cint
    a2: bool
    a3: cfloat
    a4: ptr Foo6Groundtruth

  type Foo6{.importc, completeStruct.} = object
    a1: cint
    a2: bool
    a3: cfloat
    a4: ptr Foo6

  static: doAssert Foo6.sizeof == Foo6Groundtruth.sizeof
  static: doAssert compiles(static(Foo6.sizeof))

block:
  type Foo6{.importc.} = object
    a1: cint
  doAssert compiles(Foo6.sizeof)
  static: doAssert not compiles(static(Foo6.sizeof))
  echo static(Foo6.sizeof)

when defined caseBad:
  # bad sizes => each should give an assert fail message
  block:
    type Foo2AliasBad{.importc: "struct Foo2", size: 1.} = object
      a: cint
    discard Foo2AliasBad.default

  block:
    type Foo5{.importc.} = array[4, cint]
    discard Foo5.default

  block:
    type Foo5{.importc.} = array[3, bool]
    discard Foo5.default

  block:
    type Foo6{.importc, completeStruct.} = object
      a1: cint
      # a2: bool # missing this should trigger assert fail
      a3: cfloat
      a4: ptr Foo6
    discard Foo6.default

  when false:
    block:
      # pre-existing BUG: this should give a CT error in semcheck because `size`
      # disagrees with `array[3, cint]`
      type Foo5{.importc, size: 1.} = array[3, cint]
      discard Foo5.default
