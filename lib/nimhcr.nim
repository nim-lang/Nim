#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This is the Nim hot code reloading run-time for the native targets.
##
## This minimal dynamic library is the only component that is not subject
## to reloading when the `hotCodeReloading` build mode is enabled.
## It's responsible for providing a permanent memory location for all
## globals and procs within a program. For globals, this is easily achieved
## by storing them on the heap. For procs, we produce on the fly simple
## trampolines that can be dynamically overwritten to jump to a different
## target. In the host program, all globals and procs are first registered
## here with ``registerGlobal`` and ``registerProc`` and then the returned
## permanent locations are used in every reference to these symbols onwards.

when defined(hotcodereloading) or defined(createNimHcr):
  const
    nimhcrExports = "nimhcr_$1"
    dllExt = when defined(windows): "dll"
            elif defined(macosx): "dylib"
            else: "so"
  type
    GetProcAddrType = proc (h: pointer, sym: cstring): pointer {.nimcall.}

when defined(createNimHcr):
  when system.appType != "lib":
    {.error: "This file has to be compiled as a library!".}

  import tables, os, strutils, reservedmem, dynlib, times, sets

  when false:
    proc trace(input: string): void = echo input
  else:
    proc trace(input: string): void = discard

  {.pragma: nimhcr, compilerProc, exportc: nimhcrExports, dynlib.}

  when hostCPU in ["i386", "amd64"]:
    type
      ShortJumpInstruction {.packed.} = object
        opcode: byte
        offset: int32

      LongJumpInstruction {.packed.} = object
        opcode1: byte
        opcode2: byte
        offset: int32
        absoluteAddr: pointer

    proc writeJump(jumpTableEntry: ptr LongJumpInstruction, targetFn: pointer) =
      let
        jumpFrom = jumpTableEntry.shift(sizeof(ShortJumpInstruction))
        jumpDistance = distance(jumpFrom, targetFn)

      if abs(jumpDistance) < 0x7fff0000:
        let shortJump = cast[ptr ShortJumpInstruction](jumpTableEntry)
        shortJump.opcode = 0xE9 # relative jump
        shortJump.offset = int32(jumpDistance)
      else:
        jumpTableEntry.opcode1 = 0xff # indirect absolute jump
        jumpTableEntry.opcode2 = 0x25
        when hostCPU == "i386":
          # on x86 we write the absolute address of the following pointer
          jumpTableEntry.offset = cast[int32](addr jumpTableEntry.absoluteAddr)
        else:
          # on x64, we use a relative address for the same location
          jumpTableEntry.offset = 0
        jumpTableEntry.absoluteAddr = targetFn

  elif hostCPU == "arm":
    const jumpSize = 8
  elif hostCPU == "arm64":
    const jumpSize = 16

  const defaultJumpTableSize = case hostCPU
                               of "i386": 50
                               of "amd64": 500
                               else: 50

  let jumpTableSizeStr = getEnv("HOT_CODE_RELOADING_JUMP_TABLE_SIZE")
  let jumpTableSize = if jumpTableSizeStr.len > 0: parseInt(jumpTableSizeStr)
                      else: defaultJumpTableSize

  # TODO: perhaps keep track of free slots due to removed procs using a free list
  var jumpTable = ReservedMemSeq[LongJumpInstruction].init(
    memStart = cast[pointer](0x10000000),
    maxLen = jumpTableSize * 1024 * 1024 div sizeof(LongJumpInstruction),
    accessFlags = memExecReadWrite)

  type
    SKind = enum
      sProc,
      sGlobal
    Symbol = object
      case kind*: SKind
      of sProc:
        jump: ptr LongJumpInstruction
      of sGlobal:
        p: pointer
      gen: int
    ModuleDesc = object
      symbols: Table[string, Symbol]
      imports: seq[string]
      handle: LibHandle
      gen: int
      lastModification: Time
      callbacks: seq[tuple[isBefore: bool, globalVar: string, cb: proc (): void]]

  proc newModuleDesc(): ModuleDesc = result.symbols = initTable[string, Symbol]()

  # the global state necessary for traversing and reloading the module import tree
  var modules = initTable[string, ModuleDesc]()
  var root: string
  var generation = 0

  # necessary for registering callbacks
  var currentModule: string
  var lastRegisteredGlobal: string

  var hcrDynlibHandle: pointer
  var getProcAddr: GetProcAddrType

  proc registerProc*(module: cstring, name: cstring, fn: pointer): pointer {.nimhcr.} =
    trace "  register proc: " & $module & " " & $name
    # Please note: We must allocate a local copy of the strings, because the supplied
    # `cstring` will reside in the data segment of a DLL that will be later unloaded.
    let name = $name
    let module = $module

    var jumpTableEntryAddr: ptr LongJumpInstruction

    modules[module].symbols.withValue(name, trampoline):
      jumpTableEntryAddr = trampoline[].jump
      trace "    update proc: " & name
      trampoline[].gen = generation
    do:
      let len = jumpTable.len
      jumpTable.setLen(len + 1)
      jumpTableEntryAddr = addr jumpTable[len]
      modules[module].symbols[name] = Symbol(kind: sProc, jump: jumpTableEntryAddr, gen: generation)

    writeJump jumpTableEntryAddr, fn
    return jumpTableEntryAddr

  proc getProc*(module: cstring, name: cstring): pointer {.nimhcr.} =
    trace "  get proc: " & $module & " " & $name
    return modules[$module].symbols[$name].jump

  proc registerGlobal*(module: cstring, name: cstring, size: Natural, outPtr: ptr pointer): bool {.nimhcr.} =
    lastRegisteredGlobal = $name
    trace "  register global: " & $module & " " & $name
    # Please note: We must allocate local copies of the strings, because the supplied
    # `cstring` will reside in the data segment of a DLL that will be later unloaded.
    # Also using a ptr pointer instead of a var pointer (an output parameter)
    # because for the C++ backend var parameters use references and in this use case
    # it is not possible to cast an int* (for example) to a void* and then pass it
    # to void*& since the casting yields an rvalue and references bind only to lvalues.
    let name = $name
    let module = $module

    modules[module].symbols.withValue(name, global):
      outPtr[] = global[].p
      trace "    update global: " & name
      global[].gen = generation
      return false
    do:
      outPtr[] = alloc0(size)
      zeroMem(outPtr[], size)
      modules[module].symbols[name] = Symbol(kind: sGlobal, p: outPtr[], gen: generation)
      return true

  proc getGlobal*(module: cstring, name: cstring): pointer {.nimhcr.} =
    trace "  get global: " & $module & " " & $name
    return modules[$module].symbols[$name].p

  proc getListOfModules(cstringArray: ptr pointer): seq[string] =
    var curr = cast[ptr cstring](cstringArray)
    while len(curr[]) > 0:
      result.add($curr[])
      curr = cast[ptr cstring](cast[int64](curr) + sizeof(ptr string))

  proc cleanupSymbol(module: string, name: string): void =
    if modules[module].symbols[name].kind == sGlobal:
      dealloc(modules[module].symbols[name].p)
    modules[module].symbols.del(name)

  proc cleanupSymbols(module: string): void =
    var toDelete: seq[string]
    for name, data in modules[module].symbols.pairs:
      if data.gen < generation:
        toDelete.add(name)
        trace "HCR delete symbol: " & name & " " & $data.gen
    for curr in toDelete:
      cleanupSymbol(module, curr)

  proc loadDll*(name: cstring): void {.nimhcr.} =
    let name = $name
    trace "HCR LOADING: " & name
    if modules.contains(name):
      unloadLib(modules[name].handle)
    else:
      modules.add(name, newModuleDesc())

    let copiedName = name & ".copy." & dllExt
    copyFile(name, copiedName)

    let lib = loadLib(copiedName)
    assert lib != nil
    modules[name].handle = lib
    modules[name].gen = generation
    modules[name].lastModification = getLastModificationTime(name)

    # update the list of imports by the module
    let getModuleListProc = cast[proc (): ptr pointer {.noconv.}](
      checkedSymAddr(lib, "HcrGetImportedModules"))
    modules[name].imports = getListOfModules(getModuleListProc())

    # Remove callbacks for this module if reloading - they will be re-registered.
    # In order for them to be re-registered we need to de-register all globals
    # that trigger the registering of callbacks through calls to registerCallbackHCR
    for curr in modules[name].callbacks:
      cleanupSymbol(name, curr.globalVar)
    modules[name].callbacks.setLen(0)

  proc initPointerData*(name: cstring): void {.nimhcr.} =
    trace "HCR Hcr/Dat init: " & $name
    cast[proc (h: pointer, gpa: GetProcAddrType): void {.noconv.}](
      checkedSymAddr(modules[$name].handle, "HcrInit000"))(hcrDynlibHandle, getProcAddr)
    cast[proc (): void {.noconv.}](checkedSymAddr(modules[$name].handle, "DatInit000"))()

  proc initGlobalScope*(name: cstring): void {.nimhcr.} =
    trace "HCR Init000: " & $name
    # set the currently inited module - necessary for registering the before/after HCR callbacks
    currentModule = $name  
    cast[proc (): void {.noconv.}](checkedSymAddr(modules[$name].handle, "Init000"))()

  proc recursiveInit(dlls: seq[string]): void =
    for curr in dlls:
      # skip updating the root or a module that has already been updated to the latest generation
      if modules.contains(curr) and modules[curr].gen >= generation:
        trace "HCR SKIP: " & curr & " gen is already: " & $modules[curr].gen
        continue
      # skip updating an unmodified module but continue traversing its dependencies
      if modules.contains(curr) and modules[curr].lastModification >= getLastModificationTime(curr):
        trace "HCR SKIP (not modified): " & curr & " " & $modules[curr].lastModification
        # update generation so module doesn't get collected
        modules[curr].gen = generation
        # recurse to imported modules - they might be changed
        recursiveInit(modules[curr].imports)
        continue
      loadDll(curr)
      # first load all dependencies of the current module and init it after that
      recursiveInit(modules[curr].imports)
      # init the current module after all its dependencies
      initPointerData(curr)
      initGlobalScope(curr)
      # cleanup old symbols which are gone now
      cleanupSymbols(curr)

  var traversedModules: HashSet[string]

  proc recursiveExecuteCallbacks(isBefore: bool, module: string): void =
    # do not process an already traversed module
    if traversedModules.containsOrIncl(module): return
    # first recurse to do a DFS traversal
    for curr in modules[module].imports:
      recursiveExecuteCallbacks(isBefore, curr)
    # and then execute the callbacks - from leaf modules all the way up to the root module
    for curr in modules[module].callbacks:
      if curr.isBefore == isBefore:
       curr.cb()

  proc initRuntime*(list_of_dlls: ptr pointer, main: cstring, handle: pointer,
    gpa: GetProcAddrType): void {.nimhcr.} =
    trace "HCR INITING: " & $main
    root = $main
    hcrDynlibHandle = handle
    getProcAddr = gpa
    # we need the root to be added as well because symbols from it will also be registered in the HCR system
    modules.add(root, newModuleDesc())
    modules[root].imports = getListOfModules(list_of_dlls)
    modules[root].gen = 1000000 # something huge so it doesn't get collected
    # recursively initialize all modules
    recursiveInit(modules[root].imports)
    # the next module to be inited will be the root
    currentModule = root
    traversedModules.init()

  proc hasAnyModuleChanged*(): bool {.nimhcr.} =
    proc recursiveChangeScan(dlls: seq[string]): bool =
      result = false
      for curr in dlls:
        if modules[curr].lastModification < getLastModificationTime(curr) or recursiveChangeScan(modules[curr].imports):
          return true
    return recursiveChangeScan(modules[root].imports)

  proc performCodeReload*(): void {.nimhcr.} =
    if not hasAnyModuleChanged():
      return

    inc(generation)
    trace "HCR RELOADING: " & $generation

    # first execute the before reload callbacks
    traversedModules.clear()
    recursiveExecuteCallbacks(true, root)

    # do the reloading
    recursiveInit(modules[root].imports)

    # execute the after reload callbacks
    traversedModules.clear()
    recursiveExecuteCallbacks(false, root)

    # collecting no longer referenced modules - based on their generation
    var toDelete: seq[string]
    for key, val in modules.pairs:
      if val.gen < generation:
        toDelete.add(key)
    for curr in toDelete:
      trace "HCR REMOVING: " & curr
      cleanupSymbols(curr)
      unloadLib(modules[curr].handle)
      modules.del(curr)

  proc registerCallbackHCR*(isBefore: bool, cb: proc (): void): bool {.nimhcr.} =
    modules[currentModule].callbacks.add((isBefore: isBefore, globalVar: lastRegisteredGlobal, cb: cb))
    return true

  proc addDummyModule*(module: cstring): void {.nimhcr.} = modules.add($module, newModuleDesc())

else:
  when defined(hotcodereloading):
    const
      nimhcrLibname = when defined(windows): "nimhcr." & dllExt
                      elif defined(macosx): "libnimhcr." & dllExt
                      else: "libnimhcr." & dllExt

    {.pragma: nimhcr, compilerProc, importc: nimhcrExports, dynlib: nimhcrLibname.}

    proc registerProc*(module: cstring, name: cstring, fn: pointer): pointer {.nimhcr.}
    proc getProc*(module: cstring, name: cstring): pointer {.nimhcr.}
    proc registerGlobal*(module: cstring, name: cstring, size: Natural, outPtr: ptr pointer): bool {.nimhcr.}
    proc getGlobal*(module: cstring, name: cstring): pointer {.nimhcr.}

    proc loadDll*(name: cstring): void {.nimhcr.}
    proc initPointerData*(name: cstring): void {.nimhcr.}
    proc initGlobalScope*(name: cstring): void {.nimhcr.}
    proc initRuntime*(list_of_dlls: ptr pointer, main: cstring, handle: pointer, gpa: GetProcAddrType): void {.nimhcr.}
    proc registerCallbackHCR*(isBefore: bool, cb: proc (): void): bool {.nimhcr.}

    # used only for testing purposes so the register/get proc/global functions don't crash
    proc addDummyModule*(module: cstring): void {.nimhcr.}

    # the following functions/templates are intended to be used by the user
    proc performCodeReload*(): void {.nimhcr.}
    proc hasAnyModuleChanged*(): bool {.nimhcr.}

    # We use a "global" to force execution while top-level statements are evaluated - this way new blocks can
    # be added when reloading (new globals can be introduced but newly written top-level code is not executed)
    template beforeCodeReload*(body: untyped) =
      let dummy = registerCallbackHCR(true, proc (): void = body)
    template afterCodeReload*(body: untyped) =
      let dummy = registerCallbackHCR(false, proc (): void = body)

  else:
    # we need these stubs so code continues to compile even when HCR is off
    proc performCodeReload*(): void = discard
    proc hasAnyModuleChanged*(): bool = discard
    template beforeCodeReload*(body: untyped) = discard
    template afterCodeReload*(body: untyped) = discard
