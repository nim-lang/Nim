type
  NativeTypeKind* = enum
    ntObject
    ntRefObject

  NativeField* = object
    name*: string
    typeSymbol*: string
    exported*: bool

  NativeType* = object
    name*: string
    nifSymbol*: string
    typeId*: string
    kind*: NativeTypeKind
    fields*: seq[NativeField]

  NativeParam* = object
    name*: string
    typeSymbol*: string

  NativeProc* = object
    name*: string
    nifSymbol*: string
    cSymbol*: string
    returnTypeSymbol*: string
    params*: seq[NativeParam]

  NativeApi* = object
    compilerVersion*: string
    targetOS*: string
    targetCPU*: string
    memoryManager*: string
    allocator*: string
    types*: seq[NativeType]
    procs*: seq[NativeProc]
