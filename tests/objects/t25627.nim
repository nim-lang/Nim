# issue #25627

import std/tables

type
  FsoKind = enum
    fsoFile
    fsoDir
    fsoLink

  FakeFso = ref object
    kind: FsoKind
    dirName: string
    files: OrderedTable[string, FakeFso]

  DirStruct = object
    root = FakeFso(kind: fsoDir, dirName: "/")

let dir = DirStruct()
doAssert dir.root.kind == fsoDir
doAssert dir.root.dirName == "/"
doAssert dir.root.files.len == 0

block:
  type
    Opt[T] = object
      when T is ref:
        val: T
        x: int
      else:
        val: T
        x: string

    DefaultOpt = ref object
      files: Opt[DefaultOpt]

    OptDirStruct = object
      root = DefaultOpt()

  let dir = OptDirStruct()
  doAssert dir.root.files.x is int

block:
  type
    Opt[T] = object
      when T is ref:
        x: int
      else:
        x: string

    Foo[T] = object
      x: Opt[T]

    Nested = ref object
      files: Foo[Nested]

  let nested = Nested()
  doAssert nested.files.x.x is int

block:
  type
    Foo[T] = object
      x = sizeof(T)

    Sized = ref object
      files: Foo[Sized]

  let sized = Sized()
  doAssert sized.files.x == sizeof(Sized)

