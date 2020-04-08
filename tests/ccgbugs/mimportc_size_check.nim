{.emit:"""
struct Foo1{
  int a;
};
struct Foo2{
  int a;
};
enum Foo3{k1, k2};
typedef enum Foo3 Foo3b;
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

when defined caseBad:
  # bad size => should assert fail
  type Foo2AliasBad{.importc: "struct Foo2", size: 1.} = object
    a: cint
  discard Foo2AliasBad.default
