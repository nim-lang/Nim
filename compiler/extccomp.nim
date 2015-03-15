#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Module providing functions for calling the different external C compilers
# Uses some hard-wired facts about each C/C++ compiler, plus options read
# from a configuration file, to provide generalized procedures to compile
# nim files.

import
  lists, ropes, os, strutils, osproc, platform, condsyms, options, msgs, crc

type 
  TSystemCC* = enum 
    ccNone, ccGcc, ccLLVM_Gcc, ccCLang, ccLcc, ccBcc, ccDmc, ccWcc, ccVcc, 
    ccTcc, ccPcc, ccUcc, ccIcl
  TInfoCCProp* = enum         # properties of the C compiler:
    hasSwitchRange,           # CC allows ranges in switch statements (GNU C)
    hasComputedGoto,          # CC has computed goto (GNU C extension)
    hasCpp,                   # CC is/contains a C++ compiler
    hasAssume,                # CC has __assume (Visual C extension)
    hasGcGuard,               # CC supports GC_GUARD to keep stack roots
    hasGnuAsm,                # CC's asm uses the absurd GNU assembler syntax
    hasNakedDeclspec,         # CC has __declspec(naked)
    hasNakedAttribute         # CC has __attribute__((naked))
  TInfoCCProps* = set[TInfoCCProp]
  TInfoCC* = tuple[
    name: string,        # the short name of the compiler
    objExt: string,      # the compiler's object file extenstion
    optSpeed: string,    # the options for optimization for speed
    optSize: string,     # the options for optimization for size
    compilerExe: string, # the compiler's executable
    cppCompiler: string, # name of the C++ compiler's executable (if supported)
    compileTmpl: string, # the compile command template
    buildGui: string,    # command to build a GUI application
    buildDll: string,    # command to build a shared library
    buildLib: string,    # command to build a static library
    linkerExe: string,   # the linker's executable (if not matching compiler's)
    linkTmpl: string,    # command to link files to produce an exe
    includeCmd: string,  # command to add an include dir
    linkDirCmd: string,  # command to add a lib dir
    linkLibCmd: string,  # command to link an external library
    debug: string,       # flags for debug build
    pic: string,         # command for position independent code
                         # used on some platforms
    asmStmtFrmt: string, # format of ASM statement
    structStmtFmt: string, # Format for struct statement
    packedPragma: string,  # Attribute/pragma to make struct packed (1-byte aligned)
    props: TInfoCCProps] # properties of the C compiler


# Configuration settings for various compilers. 
# When adding new compilers, the cmake sources could be a good reference:
# http://cmake.org/gitweb?p=cmake.git;a=tree;f=Modules/Platform;

template compiler(name: expr, settings: stmt): stmt {.immediate.} =
  proc name: TInfoCC {.compileTime.} = settings

# GNU C and C++ Compiler
compiler gcc:
  result = (
    name: "gcc",
    objExt: "o",
    optSpeed: " -O3 -ffast-math ",
    optSize: " -Os -ffast-math ",
    compilerExe: "gcc",
    cppCompiler: "g++",
    compileTmpl: "-c $options $include -o $objfile $file",
    buildGui: " -mwindows",
    buildDll: " -shared",
    buildLib: "ar rcs $libfile $objfiles",
    linkerExe: "",
    linkTmpl: "$buildgui $builddll -o $exefile $objfiles $options",
    includeCmd: " -I",
    linkDirCmd: " -L",
    linkLibCmd: " -l$1",
    debug: "",
    pic: "-fPIC",
    asmStmtFrmt: "asm($1);$n",
    structStmtFmt: "$1 $3 $2 ", # struct|union [packed] $name
    packedPragma: "__attribute__((__packed__))",
    props: {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard, hasGnuAsm,
            hasNakedAttribute})

# LLVM Frontend for GCC/G++
compiler llvmGcc:
  result = gcc() # Uses settings from GCC

  result.name = "llvm_gcc"
  result.compilerExe = "llvm-gcc"
  result.cppCompiler = "llvm-g++"
  result.buildLib = "llvm-ar rcs $libfile $objfiles"

# Clang (LLVM) C/C++ Compiler
compiler clang:
  result = llvmGcc() # Uses settings from llvmGcc

  result.name = "clang"
  result.compilerExe = "clang"
  result.cppCompiler = "clang++"

# Microsoft Visual C/C++ Compiler
compiler vcc:
  result = (
    name: "vcc",
    objExt: "obj",
    optSpeed: " /Ogityb2 /G7 /arch:SSE2 ",
    optSize: " /O1 /G7 ",
    compilerExe: "cl",
    cppCompiler: "cl",
    compileTmpl: "/c $options $include /Fo$objfile $file",
    buildGui: " /link /SUBSYSTEM:WINDOWS ",
    buildDll: " /LD",
    buildLib: "lib /OUT:$libfile $objfiles",
    linkerExe: "cl",
    linkTmpl: "$options $builddll /Fe$exefile $objfiles $buildgui",
    includeCmd: " /I",
    linkDirCmd: " /LIBPATH:",
    linkLibCmd: " $1.lib",
    debug: " /GZ /Zi ",
    pic: "",
    asmStmtFrmt: "__asm{$n$1$n}$n",
    structStmtFmt: "$3$n$1 $2",
    packedPragma: "#pragma pack(1)",
    props: {hasCpp, hasAssume, hasNakedDeclspec})

# Intel C/C++ Compiler
compiler icl:
  # Intel compilers try to imitate the native ones (gcc and msvc)
  when defined(windows):
    result = vcc()
  else:
    result = gcc()
    
  result.name = "icl"
  result.compilerExe = "icl"
  result.linkerExe = "icl"

# Local C Compiler
compiler lcc:
  result = (
    name: "lcc",
    objExt: "obj",
    optSpeed: " -O -p6 ",
    optSize: " -O -p6 ",
    compilerExe: "lcc",
    cppCompiler: "",
    compileTmpl: "$options $include -Fo$objfile $file",
    buildGui: " -subsystem windows",
    buildDll: " -dll",
    buildLib: "", # XXX: not supported yet
    linkerExe: "lcclnk",
    linkTmpl: "$options $buildgui $builddll -O $exefile $objfiles",
    includeCmd: " -I",
    linkDirCmd: "", # XXX: not supported yet
    linkLibCmd: "", # XXX: not supported yet
    debug: " -g5 ",
    pic: "",
    asmStmtFrmt: "_asm{$n$1$n}$n",
    structStmtFmt: "$1 $2",
    packedPragma: "", # XXX: not supported yet
    props: {})

# Borland C Compiler
compiler bcc:
  result = (
    name: "bcc",
    objExt: "obj",
    optSpeed: " -O2 -6 ",
    optSize: " -O1 -6 ",
    compilerExe: "bcc32",
    cppCompiler: "",
    compileTmpl: "-c $options $include -o$objfile $file",
    buildGui: " -tW",
    buildDll: " -tWD",
    buildLib: "", # XXX: not supported yet
    linkerExe: "bcc32",
    linkTmpl: "$options $buildgui $builddll -e$exefile $objfiles",
    includeCmd: " -I",
    linkDirCmd: "", # XXX: not supported yet
    linkLibCmd: "", # XXX: not supported yet
    debug: "",
    pic: "",
    asmStmtFrmt: "__asm{$n$1$n}$n",
    structStmtFmt: "$1 $2",
    packedPragma: "", # XXX: not supported yet
    props: {hasCpp})

# Digital Mars C Compiler
compiler dmc:
  result = (
    name: "dmc",
    objExt: "obj",
    optSpeed: " -ff -o -6 ",
    optSize: " -ff -o -6 ",
    compilerExe: "dmc",
    cppCompiler: "",
    compileTmpl: "-c $options $include -o$objfile $file",
    buildGui: " -L/exet:nt/su:windows",
    buildDll: " -WD",
    buildLib: "", # XXX: not supported yet
    linkerExe: "dmc",
    linkTmpl: "$options $buildgui $builddll -o$exefile $objfiles",
    includeCmd: " -I",
    linkDirCmd: "", # XXX: not supported yet
    linkLibCmd: "", # XXX: not supported yet
    debug: " -g ",
    pic: "",
    asmStmtFrmt: "__asm{$n$1$n}$n",
    structStmtFmt: "$3$n$1 $2",
    packedPragma: "#pragma pack(1)",
    props: {hasCpp})

# Watcom C Compiler
compiler wcc:
  result = (
    name: "wcc",
    objExt: "obj",
    optSpeed: " -ox -on -6 -d0 -fp6 -zW ",
    optSize: "",
    compilerExe: "wcl386",
    cppCompiler: "",
    compileTmpl: "-c $options $include -fo=$objfile $file",
    buildGui: " -bw",
    buildDll: " -bd",
    buildLib: "", # XXX: not supported yet
    linkerExe: "wcl386",
    linkTmpl: "$options $buildgui $builddll -fe=$exefile $objfiles ",
    includeCmd: " -i=",
    linkDirCmd: "", # XXX: not supported yet
    linkLibCmd: "", # XXX: not supported yet
    debug: " -d2 ",
    pic: "",
    asmStmtFrmt: "__asm{$n$1$n}$n",
    structStmtFmt: "$1 $2",
    packedPragma: "", # XXX: not supported yet
    props: {hasCpp})

# Tiny C Compiler
compiler tcc:
  result = (
    name: "tcc",
    objExt: "o",
    optSpeed: "",
    optSize: "",
    compilerExe: "tcc",
    cppCompiler: "",
    compileTmpl: "-c $options $include -o $objfile $file",
    buildGui: "UNAVAILABLE!",
    buildDll: " -shared",
    buildLib: "", # XXX: not supported yet
    linkerExe: "tcc",
    linkTmpl: "-o $exefile $options $buildgui $builddll $objfiles",
    includeCmd: " -I",
    linkDirCmd: "", # XXX: not supported yet
    linkLibCmd: "", # XXX: not supported yet
    debug: " -g ",
    pic: "",
    asmStmtFrmt: "__asm{$n$1$n}$n",
    structStmtFmt: "$1 $2",
    packedPragma: "", # XXX: not supported yet
    props: {hasSwitchRange, hasComputedGoto})

# Pelles C Compiler
compiler pcc:
  # Pelles C
  result = (
    name: "pcc",
    objExt: "obj",
    optSpeed: " -Ox ",
    optSize: " -Os ",
    compilerExe: "cc",
    cppCompiler: "",
    compileTmpl: "-c $options $include -Fo$objfile $file",
    buildGui: " -SUBSYSTEM:WINDOWS",
    buildDll: " -DLL",
    buildLib: "", # XXX: not supported yet
    linkerExe: "cc",
    linkTmpl: "$options $buildgui $builddll -OUT:$exefile $objfiles",
    includeCmd: " -I",
    linkDirCmd: "", # XXX: not supported yet
    linkLibCmd: "", # XXX: not supported yet
    debug: " -Zi ",
    pic: "",
    asmStmtFrmt: "__asm{$n$1$n}$n",
    structStmtFmt: "$1 $2",
    packedPragma: "", # XXX: not supported yet
    props: {})

# Your C Compiler
compiler ucc:
  result = (
    name: "ucc",
    objExt: "o",
    optSpeed: " -O3 ",
    optSize: " -O1 ",
    compilerExe: "cc",
    cppCompiler: "",
    compileTmpl: "-c $options $include -o $objfile $file",
    buildGui: "",
    buildDll: " -shared ",
    buildLib: "", # XXX: not supported yet
    linkerExe: "cc",
    linkTmpl: "-o $exefile $buildgui $builddll $objfiles $options",
    includeCmd: " -I",
    linkDirCmd: "", # XXX: not supported yet
    linkLibCmd: "", # XXX: not supported yet
    debug: "",
    pic: "",
    asmStmtFrmt: "__asm{$n$1$n}$n",
    structStmtFmt: "$1 $2",
    packedPragma: "", # XXX: not supported yet
    props: {})

const 
  CC*: array[succ(low(TSystemCC))..high(TSystemCC), TInfoCC] = [
    gcc(),
    llvmGcc(),
    clang(),
    lcc(),
    bcc(),
    dmc(),
    wcc(),
    vcc(),
    tcc(),
    pcc(),
    ucc(),
    icl()]

  hExt* = ".h"

var
  cCompiler* = ccGcc # the used compiler
  gMixedMode*: bool  # true if some module triggered C++ codegen
  cIncludes*: seq[string] = @[]   # directories to search for included files
  cLibs*: seq[string] = @[]       # directories to search for lib files
  cLinkedLibs*: seq[string] = @[] # libraries to link

# implementation

proc libNameTmpl(): string {.inline.} =
  result = if targetOS == osWindows: "$1.lib" else: "lib$1.a"

var 
  toLink, toCompile, externalToCompile: TLinkedList
  linkOptions: string = ""
  compileOptions: string = ""
  ccompilerpath: string = ""

proc nameToCC*(name: string): TSystemCC =
  ## Returns the kind of compiler referred to by `name`, or ccNone
  ## if the name doesn't refer to any known compiler.
  for i in countup(succ(ccNone), high(TSystemCC)): 
    if cmpIgnoreStyle(name, CC[i].name) == 0: 
      return i
  result = ccNone

proc getConfigVar(c: TSystemCC, suffix: string): string =
  # use ``cpu.os.cc`` for cross compilation, unless ``--compileOnly`` is given
  # for niminst support
  let fullSuffix =
    if gCmd == cmdCompileToCpp:
      ".cpp" & suffix
    elif gCmd == cmdCompileToOC:
      ".objc" & suffix
    elif gCmd == cmdCompileToJS:
      ".js" & suffix
    else:
      suffix

  if (platform.hostOS != targetOS or platform.hostCPU != targetCPU) and
      optCompileOnly notin gGlobalOptions:
    let fullCCname = platform.CPU[targetCPU].name & '.' & 
                     platform.OS[targetOS].name & '.' & 
                     CC[c].name & fullSuffix
    result = getConfigVar(fullCCname)
    if result.len == 0:
      # not overriden for this cross compilation setting?
      result = getConfigVar(CC[c].name & fullSuffix)
  else:
    result = getConfigVar(CC[c].name & fullSuffix)

proc setCC*(ccname: string) = 
  cCompiler = nameToCC(ccname)
  if cCompiler == ccNone: rawMessage(errUnknownCcompiler, ccname)
  compileOptions = getConfigVar(cCompiler, ".options.always")
  linkOptions = ""
  ccompilerpath = getConfigVar(cCompiler, ".path")
  for i in countup(low(CC), high(CC)): undefSymbol(CC[i].name)
  defineSymbol(CC[cCompiler].name)

proc addOpt(dest: var string, src: string) = 
  if len(dest) == 0 or dest[len(dest)-1] != ' ': add(dest, " ")
  add(dest, src)

proc addLinkOption*(option: string) =
  addOpt(linkOptions, option)

proc addCompileOption*(option: string) = 
  if strutils.find(compileOptions, option, 0) < 0: 
    addOpt(compileOptions, option)

proc initVars*() = 
  # we need to define the symbol here, because ``CC`` may have never been set!
  for i in countup(low(CC), high(CC)): undefSymbol(CC[i].name)
  defineSymbol(CC[cCompiler].name)
  addCompileOption(getConfigVar(cCompiler, ".options.always"))
  #addLinkOption(getConfigVar(cCompiler, ".options.linker"))
  if len(ccompilerpath) == 0:
    ccompilerpath = getConfigVar(cCompiler, ".path")

proc completeCFilePath*(cfile: string, createSubDir: bool = true): string = 
  result = completeGeneratedFilePath(cfile, createSubDir)

proc toObjFile*(filename: string): string = 
  # Object file for compilation
  result = changeFileExt(filename, CC[cCompiler].objExt)

proc addFileToCompile*(filename: string) =
  appendStr(toCompile, filename)

proc resetCompilationLists* =
  initLinkedList(toCompile)
  ## XXX: we must associate these with their originating module
  # when the module is loaded/unloaded it adds/removes its items
  # That's because we still need to CRC check the external files
  # Maybe we can do that in checkDep on the other hand?
  initLinkedList(externalToCompile)
  initLinkedList(toLink)

proc addFileToLink*(filename: string) =
  prependStr(toLink, filename)
  # BUGFIX: was ``appendStr``

proc execWithEcho(cmd: string, prettyCmd = ""): int =
  if optListCmd in gGlobalOptions or gVerbosity > 0:
    if prettyCmd != "":
      msgWriteln(prettyCmd)
    else:
      msgWriteln(cmd)
  result = execCmd(cmd)

proc execExternalProgram*(cmd: string, prettyCmd = "") =
  if execWithEcho(cmd, prettyCmd) != 0:
    rawMessage(errExecutionOfProgramFailed, "")

proc generateScript(projectFile: string, script: PRope) = 
  let (dir, name, ext) = splitFile(projectFile)
  writeRope(script, dir / addFileExt("compile_" & name, 
                                     platform.OS[targetOS].scriptExt))

proc getOptSpeed(c: TSystemCC): string = 
  result = getConfigVar(c, ".options.speed")
  if result == "":
    result = CC[c].optSpeed   # use default settings from this file

proc getDebug(c: TSystemCC): string = 
  result = getConfigVar(c, ".options.debug")
  if result == "":
    result = CC[c].debug      # use default settings from this file

proc getOptSize(c: TSystemCC): string = 
  result = getConfigVar(c, ".options.size")
  if result == "":
    result = CC[c].optSize    # use default settings from this file

proc noAbsolutePaths: bool {.inline.} =
  # We used to check current OS != specified OS, but this makes no sense
  # really: Cross compilation from Linux to Linux for example is entirely
  # reasonable.
  # `optGenMapping` is included here for niminst.
  result = gGlobalOptions * {optGenScript, optGenMapping} != {}

const 
  specialFileA = 42
  specialFileB = 42

var fileCounter: int

proc add(s: var string, many: openArray[string]) =
  s.add many.join

proc cFileSpecificOptions(cfilename: string): string =
  result = compileOptions
  var trunk = splitFile(cfilename).name
  if optCDebug in gGlobalOptions: 
    var key = trunk & ".debug"
    if existsConfigVar(key): addOpt(result, getConfigVar(key))
    else: addOpt(result, getDebug(cCompiler))
  if optOptimizeSpeed in gOptions:
    var key = trunk & ".speed"
    if existsConfigVar(key): addOpt(result, getConfigVar(key))
    else: addOpt(result, getOptSpeed(cCompiler))
  elif optOptimizeSize in gOptions:
    var key = trunk & ".size"
    if existsConfigVar(key): addOpt(result, getConfigVar(key))
    else: addOpt(result, getOptSize(cCompiler))
  var key = trunk & ".always"
  if existsConfigVar(key): addOpt(result, getConfigVar(key))

proc getCompileOptions: string =
  result = cFileSpecificOptions("__dummy__")

proc getLinkOptions: string =
  result = linkOptions
  for linkedLib in items(cLinkedLibs):
    result.add(CC[cCompiler].linkLibCmd % linkedLib.quoteShell)
  for libDir in items(cLibs):
    result.add([CC[cCompiler].linkDirCmd, libDir.quoteShell])

proc needsExeExt(): bool {.inline.} =
  result = (optGenScript in gGlobalOptions and targetOS == osWindows) or
           (platform.hostOS == osWindows)

proc getCompilerExe(compiler: TSystemCC): string =
  result = if gCmd == cmdCompileToCpp: CC[compiler].cppCompiler
           else: CC[compiler].compilerExe
  if result.len == 0:
    rawMessage(errCompilerDoesntSupportTarget, CC[compiler].name)

proc getLinkerExe(compiler: TSystemCC): string =
  result = if CC[compiler].linkerExe.len > 0: CC[compiler].linkerExe
           elif gMixedMode and gCmd != cmdCompileToCpp: CC[compiler].cppCompiler
           else: compiler.getCompilerExe

proc getCompileCFileCmd*(cfilename: string, isExternal = false): string = 
  var c = cCompiler
  var options = cFileSpecificOptions(cfilename)
  var exe = getConfigVar(c, ".exe")
  if exe.len == 0: exe = c.getCompilerExe
  
  if needsExeExt(): exe = addFileExt(exe, "exe")
  if optGenDynLib in gGlobalOptions and
      ospNeedsPIC in platform.OS[targetOS].props:
    add(options, ' ' & CC[c].pic)
  
  var includeCmd, compilePattern: string
  if not noAbsolutePaths():
    # compute include paths:
    includeCmd = CC[c].includeCmd & quoteShell(libpath)

    for includeDir in items(cIncludes):
      includeCmd.add([CC[c].includeCmd, includeDir.quoteShell])

    compilePattern = joinPath(ccompilerpath, exe)
  else:
    includeCmd = ""
    compilePattern = c.getCompilerExe
  
  var cfile = if noAbsolutePaths(): extractFilename(cfilename)
              else: cfilename
  var objfile = if not isExternal or noAbsolutePaths():
                  toObjFile(cfile)
                else:
                  completeCFilePath(toObjFile(cfile))
  objfile = quoteShell(objfile)
  cfile = quoteShell(cfile)
  result = quoteShell(compilePattern % [
    "file", cfile, "objfile", objfile, "options", options,
    "include", includeCmd, "nim", getPrefixDir(),
    "nim", getPrefixDir(), "lib", libpath])
  add(result, ' ')
  addf(result, CC[c].compileTmpl, [
    "file", cfile, "objfile", objfile,
    "options", options, "include", includeCmd,
    "nim", quoteShell(getPrefixDir()),
    "nim", quoteShell(getPrefixDir()),
    "lib", quoteShell(libpath)])

proc footprint(filename: string): TCrc32 =
  # note, '><' further modifies a crc value with a string.
  result = crcFromFile(filename) ><
      platform.OS[targetOS].name ><
      platform.CPU[targetCPU].name ><
      extccomp.CC[extccomp.cCompiler].name ><
      getCompileCFileCmd(filename, true)

proc externalFileChanged(filename: string): bool = 
  if gCmd notin {cmdCompileToC, cmdCompileToCpp, cmdCompileToOC, cmdCompileToLLVM}:
    return false

  var crcFile = toGeneratedFile(filename.withPackageName, "crc")
  var currentCrc = int(footprint(filename))
  var f: File
  if open(f, crcFile, fmRead): 
    var line = newStringOfCap(40)
    if not f.readLine(line): line = "0"
    close(f)
    var oldCrc = parseInt(line)
    result = oldCrc != currentCrc
  else:
    result = true
  if result: 
    if open(f, crcFile, fmWrite):
      f.writeln($currentCrc)
      close(f)

proc addExternalFileToCompile*(filename: string) =
  if optForceFullMake in gGlobalOptions or externalFileChanged(filename):
    appendStr(externalToCompile, filename)

proc compileCFile(list: TLinkedList, script: var PRope, cmds: var TStringSeq,
                  prettyCmds: var TStringSeq, isExternal: bool) =
  var it = PStrEntry(list.head)
  while it != nil: 
    inc(fileCounter)          # call the C compiler for the .c file:
    var compileCmd = getCompileCFileCmd(it.data, isExternal)
    if optCompileOnly notin gGlobalOptions: 
      add(cmds, compileCmd)
      let (dir, name, ext) = splitFile(it.data)
      add(prettyCmds, "CC: " & name)
    if optGenScript in gGlobalOptions: 
      app(script, compileCmd)
      app(script, tnl)
    it = PStrEntry(it.next)

proc callCCompiler*(projectfile: string) =
  var 
    linkCmd, buildgui, builddll: string
  if gGlobalOptions * {optCompileOnly, optGenScript} == {optCompileOnly}: 
    return # speed up that call if only compiling and no script shall be
           # generated
  fileCounter = 0
  var c = cCompiler
  var script: PRope = nil
  var cmds: TStringSeq = @[]
  var prettyCmds: TStringSeq = @[]
  let prettyCb = proc (idx: int) =
    echo prettyCmds[idx]
  compileCFile(toCompile, script, cmds, prettyCmds, false)
  compileCFile(externalToCompile, script, cmds, prettyCmds, true)
  if optCompileOnly notin gGlobalOptions: 
    if gNumberOfProcessors == 0: gNumberOfProcessors = countProcessors()
    var res = 0
    if gNumberOfProcessors <= 1: 
      for i in countup(0, high(cmds)): 
        res = execWithEcho(cmds[i])
        if res != 0: rawMessage(errExecutionOfProgramFailed, [])
    elif optListCmd in gGlobalOptions or gVerbosity > 1:
      res = execProcesses(cmds, {poEchoCmd, poUsePath, poParentStreams},
                          gNumberOfProcessors)
    elif gVerbosity == 1:
      res = execProcesses(cmds, {poUsePath, poParentStreams},
                          gNumberOfProcessors, prettyCb)
    else:
      res = execProcesses(cmds, {poUsePath, poParentStreams},
                          gNumberOfProcessors)
    if res != 0:
      if gNumberOfProcessors <= 1:
        rawMessage(errExecutionOfProgramFailed, [])
      else:
        rawMessage(errGenerated, " execution of an external program failed; " &
                   "rerun with --parallelBuild:1 to see the error message")
  if optNoLinking notin gGlobalOptions:
    # call the linker:
    var it = PStrEntry(toLink.head)
    var objfiles = ""
    while it != nil:
      let objFile = if noAbsolutePaths(): it.data.extractFilename else: it.data
      add(objfiles, ' ')
      add(objfiles, quoteShell(
          addFileExt(objFile, CC[cCompiler].objExt)))
      it = PStrEntry(it.next)

    if optGenStaticLib in gGlobalOptions:
      linkCmd = CC[c].buildLib % ["libfile", (libNameTmpl() % gProjectName),
                                  "objfiles", objfiles]
    else:
      var linkerExe = getConfigVar(c, ".linkerexe")
      if len(linkerExe) == 0: linkerExe = c.getLinkerExe
      if needsExeExt(): linkerExe = addFileExt(linkerExe, "exe")
      if noAbsolutePaths(): linkCmd = quoteShell(linkerExe)
      else: linkCmd = quoteShell(joinPath(ccompilerpath, linkerExe))
      if optGenGuiApp in gGlobalOptions: buildgui = CC[c].buildGui
      else: buildgui = ""
      var exefile: string
      if optGenDynLib in gGlobalOptions:
        exefile = platform.OS[targetOS].dllFrmt % splitFile(projectfile).name
        builddll = CC[c].buildDll
      else:
        exefile = splitFile(projectfile).name & platform.OS[targetOS].exeExt
        builddll = ""
      if options.outFile.len > 0: 
        exefile = options.outFile.expandTilde
      if not noAbsolutePaths():
        if not exefile.isAbsolute():
          exefile = joinPath(splitFile(projectfile).dir, exefile)
      exefile = quoteShell(exefile)
      let linkOptions = getLinkOptions() & " " & 
                        getConfigVar(cCompiler, ".options.linker")
      linkCmd = quoteShell(linkCmd % ["builddll", builddll,
          "buildgui", buildgui, "options", linkOptions, "objfiles", objfiles,
          "exefile", exefile, "nim", getPrefixDir(), "lib", libpath])
      linkCmd.add ' '
      addf(linkCmd, CC[c].linkTmpl, ["builddll", builddll,
          "buildgui", buildgui, "options", linkOptions,
          "objfiles", objfiles, "exefile", exefile,
          "nim", quoteShell(getPrefixDir()),
          "lib", quoteShell(libpath)])
    if optCompileOnly notin gGlobalOptions:
      if gVerbosity == 1:
        execExternalProgram(linkCmd, "[Linking]")
      else:
        execExternalProgram(linkCmd)
  else:
    linkCmd = ""
  if optGenScript in gGlobalOptions:
    app(script, linkCmd)
    app(script, tnl)
    generateScript(projectfile, script)

proc genMappingFiles(list: TLinkedList): PRope = 
  var it = PStrEntry(list.head)
  while it != nil: 
    appf(result, "--file:r\"$1\"$N", [toRope(it.data)])
    it = PStrEntry(it.next)

proc writeMapping*(gSymbolMapping: PRope) = 
  if optGenMapping notin gGlobalOptions: return 
  var code = toRope("[C_Files]\n")
  app(code, genMappingFiles(toCompile))
  app(code, genMappingFiles(externalToCompile))
  app(code, "\n[C_Compiler]\nFlags=")
  app(code, strutils.escape(getCompileOptions()))
  
  app(code, "\n[Linker]\nFlags=")
  app(code, strutils.escape(getLinkOptions() & " " & 
                            getConfigVar(cCompiler, ".options.linker")))

  app(code, "\n[Environment]\nlibpath=")
  app(code, strutils.escape(libpath))
  
  appf(code, "\n[Symbols]$n$1", [gSymbolMapping])
  writeRope(code, joinPath(gProjectPath, "mapping.txt"))
