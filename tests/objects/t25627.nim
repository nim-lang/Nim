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
