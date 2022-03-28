discard """
batchable: false
"""

#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This is the Nim hot code reloading run-time for the native targets.
#
# This minimal dynamic library is not subject to reloading when the
# `hotCodeReloading` build mode is enabled. It's responsible for providing
# a permanent memory location for all globals and procs within a program
# and orchestrating the reloading. For globals, this is easily achieved
# by storing them on the heap. For procs, we produce on the fly simple
# trampolines that can be dynamically overwritten to jump to a different
# target. In the host program, all globals and procs are first registered
# here with `hcrRegisterGlobal` and `hcrRegisterProc` and then the
# returned permanent locations are used in every reference to these symbols
# onwards.
#
# Detailed description:
#
# When code is compiled with the hotCodeReloading option for native targets
# a couple of things happen for all modules in a project:
# - the useNimRtl option is forced (including when building the HCR runtime too)
# - all modules of a target get built into separate shared libraries
#   - the smallest granularity of reloads is modules
#   - for each .c (or .cpp) in the corresponding nimcache folder of the project
#     a shared object is built with the name of the source file + DLL extension
#   - only the main module produces whatever the original project type intends
#     (again in nimcache) and is then copied to its original destination
#   - linking is done in parallel - just like compilation
# - function calls to functions from the same project go through function pointers:
#   - with a few exceptions - see the nonReloadable pragma
#   - the forward declarations of the original functions become function
#     pointers as static globals with the same names
#   - the original function definitions get suffixed with <name>_actual
#   - the function pointers get initialized with the address of the corresponding
#     function in the DatInit of their module through a call to either hcrRegisterProc
#     or hcrGetProc. When being registered, the <name>_actual address is passed to
#     hcrRegisterProc and a permanent location is returned and assigned to the pointer.
#     This way the implementation (<name>_actual) can change but the address for it
#     will be the same - this works by just updating a jump instruction (trampoline).
#     For functions from other modules hcrGetProc is used (after they are registered).
# - globals are initialized only once and their state is preserved
#   - including locals with the {.global.} pragma
#   - their definitions are changed into pointer definitions which are initialized
#     in the DatInit() of their module with calls to hcrRegisterGlobal (supplying the
#     size of the type that this HCR runtime should allocate) and a bool is returned
#     which when true triggers the initialization code for the global (only once).
#     Globals from other modules: a global pointer coupled with a hcrGetGlobal call.
#   - globals which have already been initialized cannot have their values changed
#     by changing their initialization - use a handler or some other mechanism
#   - new globals can be introduced when reloading
# - top-level code (global scope) is executed only once - at the first module load
# - the runtime knows every symbol's module owner (globals and procs)
# - both the RTL and HCR shared libraries need to be near the program for execution
#   - same folder, in the PATH or LD_LIBRARY_PATH env var, etc (depending on OS)
# - the main module is responsible for initializing the HCR runtime
#   - the main module loads the RTL and HCR shared objects
#   - after that a call to hcrInit() is done in the main module which triggers
#     the loading of all modules the main one imports, and doing that for the
#     dependencies of each module recursively. Basically a DFS traversal.
#   - then initialization takes place with several passes over all modules:
#     - HcrInit - initializes the pointers for HCR procs such as hcrRegisterProc
#     - HcrCreateTypeInfos - creates globals which will be referenced in the next pass
#     - DatInit - usual dat init + register/get procs and get globals
#     - Init - it does the following multiplexed operations:
#       - register globals (if already registered - then just retrieve pointer)
#       - execute top level scope (only if loaded for the first time)
#   - when modules are loaded the originally built shared libraries get copied in
#     the same folder and the copies are loaded instead of the original files
#   - a module import tree is built in the runtime (and maintained when reloading)
# - hcrPerformCodeReload
#   - named `performCodeReload`, requires the hotcodereloading module
#   - explicitly called by the user - the current active callstack shouldn't contain
#     any functions which are defined in modules that will be reloaded (or crash!).
#     The reason is that old dynamic libraries get unloaded.
#     Example:
#       if A is the main module and it imports B, then only B is reloadable and only
#       if when calling hcrPerformCodeReload there is no function defined in B in the
#       current active callstack at the point of the call (it has to be done from A)
#   - for reloading to take place the user has to have rebuilt parts of the application
#     without changes affecting the main module in any way - it shouldn't be rebuilt.
#   - to determine what needs to be reloaded the runtime starts traversing the import
#     tree from the root and checks the timestamps of the loaded shared objects
#   - modules that are no longer referenced are unloaded and cleaned up properly
#   - symbols (procs/globals) that have been removed in the code are also cleaned up
#     - so changing the init of a global does nothing, but removing it, reloading,
#       and then re-introducing it with a new initializer works
#   - new modules can be imported, and imports can also be reodereded/removed
#   - hcrReloadNeeded() can be used to determine if any module needs reloading
#     - named `hasAnyModuleChanged`, requires the hotcodereloading module
# - code in the beforeCodeReload/afterCodeReload handlers is executed on each reload
#   - require the hotcodereloading module
#   - such handlers can be added and removed
#   - before each reload all "beforeCodeReload" handlers are executed and after
#     that all handlers (including "after") from the particular module are deleted
#   - the order of execution is the same as the order of top-level code execution.
#     Example: if A imports B which imports C, then all handlers in C will be executed
#     first (from top to bottom) followed by all from B and lastly all from A
#   - after the reload all "after" handlers are executed the same way as "before"
#   - the handlers for a reloaded module are always removed when reloading and then
#     registered when the top-level scope is executed (thanks to `executeOnReload`)
#
# TODO next:
#
# - implement the before/after handlers and hasModuleChanged for the javascript target
# - ARM support for the trampolines
# - investigate:
#   - soon the system module might be importing other modules - the init order...?
#     (revert https://github.com/nim-lang/Nim/pull/11971 when working on this)
#   - rethink the closure iterators
#     - ability to keep old versions of dynamic libraries alive
#       - because of async server code
#       - perhaps with refcounting of .dlls for unfinished closures
#   - linking with static libs
#     - all shared objects for each module will (probably) have to link to them
#       - state in static libs gets duplicated
#       - linking is slow and therefore iteration time suffers
#         - have just a single .dll for all .nim files and bulk reload?
#   - think about the compile/link/passc/passl/emit/injectStmt pragmas
#     - if a passc pragma is introduced (either written or dragged in by a new
#       import) the whole command line for compilation changes - for example:
#         winlean.nim: {.passc: "-DWIN32_LEAN_AND_MEAN".}
#   - play with plugins/dlls/lfIndirect/lfDynamicLib/lfExportLib - shouldn't add an extra '*'
#   - everything thread-local related
# - tests
#   - add a new travis build matrix entry which builds everything with HCR enabled
#     - currently building with useNimRtl is problematic - lots of problems...
#     - how to supply the nimrtl/nimhcr shared objects to all test binaries...?
#     - think about building to C++ instead of only to C - added type safety
#   - run tests through valgrind and the sanitizers!
#
# TODO - nice to have cool stuff:
#
# - separate handling of global state for much faster reloading and manipulation
#   - imagine sliders in an IDE for tweaking variables
#   - perhaps using shared memory
# - multi-dll projects - how everything can be reloaded..?
#   - a single HCR instance shared across multiple .dlls
#   - instead of having to call hcrPerformCodeReload from a function in each dll
#     - which currently renders the main module of each dll not reloadable
# - ability to check with the current callstack if a reload is "legal"
#   - if it is in any function which is in a module about to be reloaded ==> error
# - pragma annotations for files - to be excluded from dll shenanigans
#   - for such file-global pragmas look at codeReordering or injectStmt
#   - how would the initialization order be kept? messy...
# - C code calling stable exportc interface of nim code (for bindings)
#   - generate proxy functions with the stable names
#     - in a non-reloadable part (the main binary) that call the function pointers
#     - parameter passing/forwarding - how? use the same trampoline jumping?
#     - extracting the dependencies for these stubs/proxies will be hard...
# - changing memory layout of types - detecting this..?
#   - implement with registerType() call to HCR runtime...?
#     - and checking if a previously registered type matches
#   - issue an error
#     - or let the user handle this by transferring the state properly
#       - perhaps in the before/afterCodeReload handlers
# - implement executeOnReload for global vars too - not just statements (and document!)
# - cleanup at shutdown - freeing all globals
# - fallback mechanism if the program crashes (the program should detect crashes
#   by itself using SEH/signals on Windows/Unix) - should be able to revert to
#   previous versions of the .dlls by calling some function from HCR
# - improve runtime performance - possibilities
#   - implement a way for multiple .nim files to be bundled into the same dll
#     and have all calls within that domain to use the "_actual" versions of
#     procs so there are no indirections (or the ability to just bundle everything
#     except for a few unreloadable modules into a single mega reloadable dll)
#   - try to load the .dlls at specific addresses of memory (close to each other)
#     allocated with execution flags - check this: https://github.com/fancycode/MemoryModule
#
# TODO - unimportant:
#
# - have a "bad call" trampoline that all no-longer-present functions are routed to call there
#     - so the user gets some error msg if he calls a dangling pointer instead of a crash
# - before/afterCodeReload and hasModuleChanged should be accessible only where appropriate
# - nim_program_result is inaccessible in HCR mode from external C code (see nimbase.h)
# - proper .json build file - but the format is different... multiple link commands...
# - avoid registering globals on each loop when using an iterator in global scope
#
# TODO - REPL:
# - proper way (as proposed by Zahary):
#   - parse the input code and put everything in global scope except for
#     statements with side effects only - those go in afterCodeReload blocks
# - my very hacky idea: just append to a closure iterator the new statements
#   followed by a yield statement. So far I can think of 2 problems:
#   - import and some other code cannot be written inside of a proc -
#     has to be parsed and extracted in the outer scope
#   - when new variables are created they are actually locals to the closure
#     so the struct for the closure state grows in memory, but it has already
#     been allocated when the closure was created with the previous smaller size.
#     That would lead to working with memory outside of the initially allocated
#     block. Perhaps something can be done about this - some way of re-allocating
#     the state and transferring the old...

when not defined(js) and (defined(hotcodereloading) or
                          defined(createNimHcr) or
                          defined(testNimHcr)):
  const
    dllExt = when defined(windows): "dll"
             elif defined(macosx): "dylib"
             else: "so"
  type
    HcrProcGetter* = proc (libHandle: pointer, procName: cstring): pointer {.nimcall.}
    HcrGcMarkerProc = proc () {.nimcall, raises: [].}
    HcrModuleInitializer* = proc () {.nimcall.}

when defined(createNimHcr):
  when system.appType != "lib":
    {.error: "This file has to be compiled as a library!".}

  import os, tables, sets, times, strutils, reservedmem, dynlib

  template trace(args: varargs[untyped]) =
    when defined(testNimHcr) or defined(traceHcr):
      echo args

  proc sanitize(arg: Time): string =
    when defined(testNimHcr): return "<time>"
    else: return $arg

  proc sanitize(arg: string|cstring): string =
    when defined(testNimHcr): return ($arg).splitFile.name.splitFile.name
    else: return $arg

  {.pragma: nimhcr, compilerproc, exportc, dynlib.}

  # XXX these types are CPU specific and need ARM etc support
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

  if hostCPU == "arm":
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
    ProcSym = object
      jump: ptr LongJumpInstruction
      gen: int

    GlobalVarSym = object
      p: pointer
      markerProc: HcrGcMarkerProc
      gen: int

    ModuleDesc = object
      procs: Table[string, ProcSym]
      globals: Table[string, GlobalVarSym]
      imports: seq[string]
      handle: LibHandle
      hash: string
      gen: int
      lastModification: Time
      handlers: seq[tuple[isBefore: bool, cb: proc ()]]

  proc newModuleDesc(): ModuleDesc =
    result.procs = initTable[string, ProcSym]()
    result.globals = initTable[string, GlobalVarSym]()
    result.handle = nil
    result.gen = -1
    result.lastModification = low(Time)

  # the global state necessary for traversing and reloading the module import tree
  var modules = initTable[string, ModuleDesc]()
  var root: string
  var system: string
  var mainDatInit: HcrModuleInitializer
  var generation = 0

  # necessary for queries such as "has module X changed" - contains all but the main module
  var hashToModuleMap = initTable[string, string]()

  # necessary for registering handlers and keeping them up-to-date
  var currentModule: string

  # supplied from the main module - used by others to initialize pointers to this runtime
  var hcrDynlibHandle: pointer
  var getProcAddr: HcrProcGetter

  proc hcrRegisterProc*(module: cstring, name: cstring, fn: pointer): pointer {.nimhcr.} =
    trace "  register proc: ", module.sanitize, " ", name
    # Please note: We must allocate a local copy of the strings, because the supplied
    # `cstring` will reside in the data segment of a DLL that will be later unloaded.
    let name = $name
    let module = $module

    var jumpTableEntryAddr: ptr LongJumpInstruction

    modules[module].procs.withValue(name, p):
      trace "    update proc: ", name
      jumpTableEntryAddr = p.jump
      p.gen = generation
    do:
      let len = jumpTable.len
      jumpTable.setLen(len + 1)
      jumpTableEntryAddr = addr jumpTable[len]
      modules[module].procs[name] = ProcSym(jump: jumpTableEntryAddr, gen: generation)

    writeJump jumpTableEntryAddr, fn
    return jumpTableEntryAddr

  proc hcrGetProc*(module: cstring, name: cstring): pointer {.nimhcr.} =
    trace "  get proc: ", module.sanitize, " ", name
    return modules[$module].procs.getOrDefault($name, ProcSym()).jump

  proc hcrRegisterGlobal*(module: cstring,
                          name: cstring,
                          size: Natural,
                          gcMarker: HcrGcMarkerProc,
                          outPtr: ptr pointer): bool {.nimhcr.} =
    trace "  register global: ", module.sanitize, " ", name
    # Please note: We must allocate local copies of the strings, because the supplied
    # `cstring` will reside in the data segment of a DLL that will be later unloaded.
    # Also using a ptr pointer instead of a var pointer (an output parameter)
    # because for the C++ backend var parameters use references and in this use case
    # it is not possible to cast an int* (for example) to a void* and then pass it
    # to void*& since the casting yields an rvalue and references bind only to lvalues.
    let name = $name
    let module = $module

    modules[module].globals.withValue(name, global):
      trace "    update global: ", name
      outPtr[] = global.p
      global.gen = generation
      global.markerProc = gcMarker
      return false
    do:
      outPtr[] = alloc0(size)
      modules[module].globals[name] = GlobalVarSym(p: outPtr[],
                                                   gen: generation,
                                                   markerProc: gcMarker)
      return true

  proc hcrGetGlobal*(module: cstring, name: cstring): pointer {.nimhcr.} =
    trace "  get global: ", module.sanitize, " ", name
    return modules[$module].globals[$name].p

  proc getListOfModules(cstringArray: ptr pointer): seq[string] =
    var curr = cast[ptr cstring](cstringArray)
    while len(curr[]) > 0:
      result.add($curr[])
      curr = cast[ptr cstring](cast[int64](curr) + sizeof(ptr cstring))

  template cleanup(collection, body) =
    var toDelete: seq[string]
    for name, data in collection.pairs:
      if data.gen < generation:
        toDelete.add(name)
        trace "HCR Cleaning ", astToStr(collection), " :: ", name, " ", data.gen
    for name {.inject.} in toDelete:
      body

  proc cleanupGlobal(module: string, name: string) =
    var g: GlobalVarSym
    if modules[module].globals.take(name, g):
      dealloc g.p

  proc cleanupSymbols(module: string) =
    cleanup modules[module].globals:
      cleanupGlobal(module, name)

    cleanup modules[module].procs:
      modules[module].procs.del(name)

  proc unloadDll(name: string) =
    if modules[name].handle != nil:
      unloadLib(modules[name].handle)

  proc loadDll(name: cstring) {.nimhcr.} =
    let name = $name
    trace "HCR LOADING: ", name.sanitize
    if modules.contains(name):
      unloadDll(name)
    else:
      modules[name] = newModuleDesc()

    let copiedName = name & ".copy." & dllExt
    copyFileWithPermissions(name, copiedName)

    let lib = loadLib(copiedName)
    assert lib != nil
    modules[name].handle = lib
    modules[name].gen = generation
    modules[name].lastModification = getLastModificationTime(name)

    # update the list of imports by the module
    let getImportsProc = cast[proc (): ptr pointer {.nimcall.}](
      checkedSymAddr(lib, "HcrGetImportedModules"))
    modules[name].imports = getListOfModules(getImportsProc())
    # get the hash of the module
    let getHashProc = cast[proc (): cstring {.nimcall.}](
      checkedSymAddr(lib, "HcrGetSigHash"))
    modules[name].hash = $getHashProc()
    hashToModuleMap[modules[name].hash] = name

    # Remove handlers for this module if reloading - they will be re-registered.
    # In order for them to be re-registered we need to de-register all globals
    # that trigger the registering of handlers through calls to hcrAddEventHandler
    modules[name].handlers.setLen(0)

  proc initHcrData(name: cstring) {.nimhcr.} =
    trace "HCR Hcr init: ", name.sanitize
    cast[proc (h: pointer, gpa: HcrProcGetter) {.nimcall.}](
      checkedSymAddr(modules[$name].handle, "HcrInit000"))(hcrDynlibHandle, getProcAddr)

  proc initTypeInfoGlobals(name: cstring) {.nimhcr.} =
    trace "HCR TypeInfo globals init: ", name.sanitize
    cast[HcrModuleInitializer](checkedSymAddr(modules[$name].handle, "HcrCreateTypeInfos"))()

  proc initPointerData(name: cstring) {.nimhcr.} =
    trace "HCR Dat init: ", name.sanitize
    cast[HcrModuleInitializer](checkedSymAddr(modules[$name].handle, "DatInit000"))()

  proc initGlobalScope(name: cstring) {.nimhcr.} =
    trace "HCR Init000: ", name.sanitize
    # set the currently inited module - necessary for registering the before/after HCR handlers
    currentModule = $name
    cast[HcrModuleInitializer](checkedSymAddr(modules[$name].handle, "Init000"))()

  var modulesToInit: seq[string] = @[]
  var allModulesOrderedByDFS: seq[string] = @[]

  proc recursiveDiscovery(dlls: seq[string]) =
    for curr in dlls:
      if modules.contains(curr):
        # skip updating modules that have already been updated to the latest generation
        if modules[curr].gen >= generation:
          trace "HCR SKIP: ", curr.sanitize, " gen is already: ", modules[curr].gen
          continue
        # skip updating an unmodified module but continue traversing its dependencies
        if modules[curr].lastModification >= getLastModificationTime(curr):
          trace "HCR SKIP (not modified): ", curr.sanitize, " ", modules[curr].lastModification.sanitize
          # update generation so module doesn't get collected
          modules[curr].gen = generation
          # recurse to imported modules - they might be changed
          recursiveDiscovery(modules[curr].imports)
          allModulesOrderedByDFS.add(curr)
          continue
      loadDll(curr)
      # first load all dependencies of the current module and init it after that
      recursiveDiscovery(modules[curr].imports)

      allModulesOrderedByDFS.add(curr)
      modulesToInit.add(curr)

  proc initModules() =
    # first init the pointers to hcr functions and also do the registering of typeinfo globals
    for curr in modulesToInit:
      initHcrData(curr)
      initTypeInfoGlobals(curr)
    # for now system always gets fully inited before any other module (including when reloading)
    initPointerData(system)
    initGlobalScope(system)
    # proceed with the DatInit calls - for all modules - including the main one!
    for curr in allModulesOrderedByDFS:
      if curr != system:
        initPointerData(curr)
    mainDatInit()
    # execute top-level code (in global scope)
    for curr in modulesToInit:
      if curr != system:
        initGlobalScope(curr)
    # cleanup old symbols which are gone now
    for curr in modulesToInit:
      cleanupSymbols(curr)

  proc hcrInit*(moduleList: ptr pointer, main, sys: cstring,
                datInit: HcrModuleInitializer, handle: pointer, gpa: HcrProcGetter) {.nimhcr.} =
    trace "HCR INITING: ", main.sanitize, " gen: ", generation
    # initialize globals
    root = $main
    system = $sys
    mainDatInit = datInit
    hcrDynlibHandle = handle
    getProcAddr = gpa
    # the root is already added and we need it because symbols from it will also be registered in the HCR system
    modules[root].imports = getListOfModules(moduleList)
    modules[root].gen = high(int) # something huge so it doesn't get collected
    # recursively initialize all modules
    recursiveDiscovery(modules[root].imports)
    initModules()
    # the next module to be inited will be the root
    currentModule = root

  proc hcrHasModuleChanged*(moduleHash: string): bool {.nimhcr.} =
    let module = hashToModuleMap[moduleHash]
    return modules[module].lastModification < getLastModificationTime(module)

  proc hcrReloadNeeded*(): bool {.nimhcr.} =
    for hash, _ in hashToModuleMap:
      if hcrHasModuleChanged(hash):
        return true
    return false

  proc hcrPerformCodeReload*() {.nimhcr.} =
    if not hcrReloadNeeded():
      trace "HCR - no changes"
      return

    # We disable the GC during the reload, because the reloading procedures
    # will replace type info objects and GC marker procs. This seems to create
    # problems when the GC is executed while the reload is underway.
    # Future versions of NIMHCR won't use the GC, because all globals and the
    # metadata needed to access them will be placed in shared memory, so they
    # can be manipulated from external programs without reloading.
    GC_disable()
    defer: GC_enable()

    inc(generation)
    trace "HCR RELOADING: ", generation

    var traversedHandlerModules = initHashSet[string]()

    proc recursiveExecuteHandlers(isBefore: bool, module: string) =
      # do not process an already traversed module
      if traversedHandlerModules.containsOrIncl(module): return
      traversedHandlerModules.incl module
      # first recurse to do a DFS traversal
      for curr in modules[module].imports:
        recursiveExecuteHandlers(isBefore, curr)
      # and then execute the handlers - from leaf modules all the way up to the root module
      for curr in modules[module].handlers:
        if curr.isBefore == isBefore:
         curr.cb()

    # first execute the before reload handlers
    traversedHandlerModules.clear()
    recursiveExecuteHandlers(true, root)

    # do the reloading
    modulesToInit = @[]
    allModulesOrderedByDFS = @[]
    recursiveDiscovery(modules[root].imports)
    initModules()

    # execute the after reload handlers
    traversedHandlerModules.clear()
    recursiveExecuteHandlers(false, root)

    # collecting no longer referenced modules - based on their generation
    cleanup modules:
      cleanupSymbols(name)
      unloadDll(name)
      hashToModuleMap.del(modules[name].hash)
      modules.del(name)

  proc hcrAddEventHandler*(isBefore: bool, cb: proc ()) {.nimhcr.} =
    modules[currentModule].handlers.add(
      (isBefore: isBefore, cb: cb))

  proc hcrAddModule*(module: cstring) {.nimhcr.} =
    if not modules.contains($module):
      modules[$module] = newModuleDesc()

  proc hcrGeneration*(): int {.nimhcr.} =
    generation

  proc hcrMarkGlobals*() {.compilerproc, exportc, dynlib, nimcall, gcsafe.} =
    # This is gcsafe, because it will be registered
    # only in the GC of the main thread.
    {.gcsafe.}:
      for _, module in modules:
        for _, global in module.globals:
          if global.markerProc != nil:
            global.markerProc()

elif defined(hotcodereloading) or defined(testNimHcr):
  when not defined(js):
    const
      nimhcrLibname = when defined(windows): "nimhcr." & dllExt
                      elif defined(macosx): "libnimhcr." & dllExt
                      else: "libnimhcr." & dllExt

    {.pragma: nimhcr, compilerproc, importc, dynlib: nimhcrLibname.}

    proc hcrRegisterProc*(module: cstring, name: cstring, fn: pointer): pointer {.nimhcr.}

    proc hcrGetProc*(module: cstring, name: cstring): pointer {.nimhcr.}

    proc hcrRegisterGlobal*(module: cstring, name: cstring, size: Natural,
                            gcMarker: HcrGcMarkerProc, outPtr: ptr pointer): bool {.nimhcr.}
    proc hcrGetGlobal*(module: cstring, name: cstring): pointer {.nimhcr.}

    proc hcrInit*(moduleList: ptr pointer,
                  main, sys: cstring,
                  datInit: HcrModuleInitializer,
                  handle: pointer,
                  gpa: HcrProcGetter) {.nimhcr.}

    proc hcrAddModule*(module: cstring) {.nimhcr.}

    proc hcrHasModuleChanged*(moduleHash: string): bool {.nimhcr.}

    proc hcrReloadNeeded*(): bool {.nimhcr.}

    proc hcrPerformCodeReload*() {.nimhcr.}

    proc hcrAddEventHandler*(isBefore: bool, cb: proc ()) {.nimhcr.}

    proc hcrMarkGlobals*() {.raises: [], nimhcr, nimcall, gcsafe.}

    when declared(nimRegisterGlobalMarker):
      nimRegisterGlobalMarker(cast[GlobalMarkerProc](hcrMarkGlobals))

  else:
    proc hcrHasModuleChanged*(moduleHash: string): bool =
      # TODO
      false

    proc hcrAddEventHandler*(isBefore: bool, cb: proc ()) =
      # TODO
      discard

