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
  # adding entries should not yield duplicate ABI checks. Currently the
  # test doesn't check for this but you can inspect the cgen'd file
  discard Foo4.default
  discard Foo4.default
  discard Foo4.default

when defined caseBad:
  # bad size => should assert fail
  type Foo2AliasBad{.importc: "struct Foo2", size: 1.} = object
    a: cint
  discard Foo2AliasBad.default
