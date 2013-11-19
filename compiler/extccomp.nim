#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# module for calling the different external C compilers
# some things are read in from the configuration file

import
  lists, ropes, os, strutils, osproc, platform, condsyms, options, msgs, crc

type 
  TSystemCC* = enum 
    ccNone, ccGcc, ccLLVM_Gcc, ccCLang, ccLcc, ccBcc, ccDmc, ccWcc, ccVcc, 
    ccTcc, ccPcc, ccUcc, ccIcl, ccGpp
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
    compileTmpl: string, # the compile command template
    buildGui: string,    # command to build a GUI application
    buildDll: string,    # command to build a shared library
    buildLib: string,    # command to build a static library
    linkerExe: string,   # the linker's executable
    linkTmpl: string,    # command to link files to produce an exe
    includeCmd: string,  # command to add an include dir
    linkDirCmd: string,  # command to add a lib dir
    linkLibCmd: string,  # command to link an external library
    debug: string,       # flags for debug build
    pic: string,         # command for position independent code
                         # used on some platforms
    asmStmtFrmt: string, # format of ASM statement
    props: TInfoCCProps] # properties of the C compiler


# Configuration settings for various compilers. 
# When adding new compilers, the cmake sources could be a good reference:
# http://cmake.org/gitweb?p=cmake.git;a=tree;f=Modules/Platform;

template compiler(name: expr, settings: stmt): stmt {.immediate.} =
  proc name: TInfoCC {.compileTime.} = settings

compiler gcc:
  result = (
    name: "gcc",
    objExt: "o",
    optSpeed: " -O3 -ffast-math ",
    optSize: " -Os -ffast-math ",
    compilerExe: "gcc",
    compileTmpl: "-c $options $include -o $objfile $file",
    buildGui: " -mwindows",
    buildDll: " -shared",
    buildLib: "ar rcs $libfile $objfiles",
    linkerExe: "gcc",
    linkTmpl: "$buildgui $builddll -o $exefile $objfiles $options",
    includeCmd: " -I",
    linkDirCmd: " -L",
    linkLibCmd: " -l$1",
    debug: "",
    pic: "-fPIC",
    asmStmtFrmt: "asm($1);$n",
    props: {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard, hasGnuAsm,
            hasNakedAttribute})
    
compiler gpp:
  result = gcc()
  
  result.name = "gpp"
  result.compilerExe = "g++"
  result.linkerExe = "g++"  

  result.buildDll = " -mdll" 
  # XXX: Hmm, I'm keeping this from the previos version, 
  # but my gcc doesn't even have such an option (is this mingw?)

compiler llvmGcc:
  result = gcc()
  
  result.name = "llvm_gcc"
  result.compilerExe = "llvm-gcc"
  result.buildLib = "llvm-ar rcs $libfile $objfiles"
  result.linkerExe = "llvm-gcc"

compiler clang:
  result = llvmGcc()

  result.name = "clang"
  result.compilerExe = "clang"
  result.linkerExe = "clang"

compiler vcc:
  result = (
    name: "vcc",
    objExt: "obj",
    optSpeed: " /Ogityb2 /G7 /arch:SSE2 ",
    optSize: " /O1 /G7 ",
    compilerExe: "cl",
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
    props: {hasCpp, hasAssume, hasNakedDeclspec})

compiler icl:
  # Intel compilers try to imitate the native ones (gcc and msvc)
  when defined(windows):
    result = vcc()
  else:
    result = gcc()

  result.name = "icl"
  result.compilerExe = "icl"
  result.linkerExe = "icl"

compiler lcc:
  result = (
    name: "lcc",
    objExt: "obj",
    optSpeed: " -O -p6 ",
    optSize: " -O -p6 ",
    compilerExe: "lcc",
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
    props: {})

compiler bcc:
  result = (
    name: "bcc",
    objExt: "obj",
    optSpeed: " -O2 -6 ",
    optSize: " -O1 -6 ",
    compilerExe: "bcc32",
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
    props: {hasCpp})

compiler dmc:
  result = (
    name: "dmc",
    objExt: "obj",
    optSpeed: " -ff -o -6 ",
    optSize: " -ff -o -6 ",
    compilerExe: "dmc",
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
    props: {hasCpp})

compiler wcc:
  result = (
    name: "wcc",
    objExt: "obj",
    optSpeed: " -ox -on -6 -d0 -fp6 -zW ",
    optSize: "",
    compilerExe: "wcl386",
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
    props: {hasCpp})

compiler tcc:
  result = (
    name: "tcc",
    objExt: "o",
    optSpeed: "",
    optSize: "",
    compilerExe: "tcc",
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
    props: {hasSwitchRange, hasComputedGoto})

compiler pcc:
  # Pelles C
  result = (
    name: "pcc",
    objExt: "obj",
    optSpeed: " -Ox ",
    optSize: " -Os ",
    compilerExe: "cc",
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
    props: {})

compiler ucc:
  result = (
    name: "ucc",
    objExt: "o",
    optSpeed: " -O3 ",
    optSize: " -O1 ",
    compilerExe: "cc",
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
    icl(),
    gpp()]

const
  hExt* = ".h"

var
  cCompiler* = ccGcc # the used compiler

  cExt* = ".c" # extension of generated C/C++ files
               # (can be changed to .cpp later)
  
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

proc NameToCC*(name: string): TSystemCC = 
  for i in countup(succ(ccNone), high(TSystemCC)): 
    if cmpIgnoreStyle(name, CC[i].name) == 0: 
      return i
  result = ccNone

proc getConfigVar(c: TSystemCC, suffix: string): string =
  # use ``cpu.os.cc`` for cross compilation, unless ``--compileOnly`` is given
  # for niminst support
  if (platform.hostOS != targetOS or platform.hostCPU != targetCPU) and
      optCompileOnly notin gGlobalOptions:
    let fullCCname = platform.cpu[targetCPU].name & '.' & 
                     platform.os[targetOS].name & '.' & 
                     CC[c].name & suffix
    result = getConfigVar(fullCCname)
    if result.len == 0:
      # not overriden for this cross compilation setting?
      result = getConfigVar(CC[c].name & suffix)
  else:
    result = getConfigVar(CC[c].name & suffix)

proc setCC*(ccname: string) = 
  ccompiler = nameToCC(ccname)
  if ccompiler == ccNone: rawMessage(errUnknownCcompiler, ccname)
  compileOptions = getConfigVar(ccompiler, ".options.always")
  linkOptions = getConfigVar(ccompiler, ".options.linker")
  ccompilerpath = getConfigVar(ccompiler, ".path")
  for i in countup(low(CC), high(CC)): undefSymbol(CC[i].name)
  defineSymbol(CC[ccompiler].name)

proc addOpt(dest: var string, src: string) = 
  if len(dest) == 0 or dest[len(dest)-1] != ' ': add(dest, " ")
  add(dest, src)

proc addLinkOption*(option: string) = 
  if find(linkOptions, option, 0) < 0: addOpt(linkOptions, option)

proc addCompileOption*(option: string) = 
  if strutils.find(compileOptions, option, 0) < 0: 
    addOpt(compileOptions, option)

proc initVars*() = 
  # we need to define the symbol here, because ``CC`` may have never been set!
  for i in countup(low(CC), high(CC)): undefSymbol(CC[i].name)
  defineSymbol(CC[ccompiler].name)
  if gCmd == cmdCompileToCpp: cExt = ".cpp"
  elif gCmd == cmdCompileToOC: cExt = ".m"
  addCompileOption(getConfigVar(ccompiler, ".options.always"))
  addLinkOption(getConfigVar(ccompiler, ".options.linker"))
  if len(ccompilerPath) == 0:
    ccompilerpath = getConfigVar(ccompiler, ".path")

proc completeCFilePath*(cfile: string, createSubDir: bool = true): string = 
  result = completeGeneratedFilePath(cfile, createSubDir)

proc toObjFile*(filenameWithoutExt: string): string = 
  # Object file for compilation
  result = changeFileExt(filenameWithoutExt, cc[ccompiler].objExt)

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

proc execExternalProgram*(cmd: string) = 
  if optListCmd in gGlobalOptions or gVerbosity > 0: MsgWriteln(cmd)
  if execCmd(cmd) != 0: rawMessage(errExecutionOfProgramFailed, "")

proc generateScript(projectFile: string, script: PRope) = 
  let (dir, name, ext) = splitFile(projectFile)
  WriteRope(script, dir / addFileExt("compile_" & name, 
                                     platform.os[targetOS].scriptExt))

proc getOptSpeed(c: TSystemCC): string = 
  result = getConfigVar(c, ".options.speed")
  if result == "":
    result = cc[c].optSpeed   # use default settings from this file

proc getDebug(c: TSystemCC): string = 
  result = getConfigVar(c, ".options.debug")
  if result == "":
    result = cc[c].debug      # use default settings from this file

proc getOptSize(c: TSystemCC): string = 
  result = getConfigVar(c, ".options.size")
  if result == "":
    result = cc[c].optSize    # use default settings from this file

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

proc add(s: var string, many: openarray[string]) =
  s.add many.join

proc CFileSpecificOptions(cfilename: string): string =
  result = compileOptions
  var trunk = splitFile(cfilename).name
  if optCDebug in gGlobalOptions: 
    var key = trunk & ".debug"
    if existsConfigVar(key): addOpt(result, getConfigVar(key))
    else: addOpt(result, getDebug(ccompiler))
  if optOptimizeSpeed in gOptions:
    var key = trunk & ".speed"
    if existsConfigVar(key): addOpt(result, getConfigVar(key))
    else: addOpt(result, getOptSpeed(ccompiler))
  elif optOptimizeSize in gOptions:
    var key = trunk & ".size"
    if existsConfigVar(key): addOpt(result, getConfigVar(key))
    else: addOpt(result, getOptSize(ccompiler))
  var key = trunk & ".always"
  if existsConfigVar(key): addOpt(result, getConfigVar(key))

proc getCompileOptions: string =
  result = CFileSpecificOptions("__dummy__")

proc getLinkOptions: string =
  result = linkOptions
  for linkedLib in items(cLinkedLibs):
    result.add(cc[ccompiler].linkLibCmd % linkedLib.quoteIfContainsWhite)
  for libDir in items(cLibs):
    result.add([cc[ccompiler].linkDirCmd, libDir.quoteIfContainsWhite])

proc needsExeExt(): bool {.inline.} =
  result = (optGenScript in gGlobalOptions and targetOS == osWindows) or
                                       (platform.hostOS == osWindows)

proc getCompileCFileCmd*(cfilename: string, isExternal = false): string = 
  var c = ccompiler
  var options = CFileSpecificOptions(cfilename)
  var exe = getConfigVar(c, ".exe")
  if exe.len == 0: exe = cc[c].compilerExe
  
  if needsExeExt(): exe = addFileExt(exe, "exe")
  if optGenDynLib in gGlobalOptions and
      ospNeedsPIC in platform.OS[targetOS].props: 
    add(options, ' ' & cc[c].pic)
  
  var includeCmd, compilePattern: string
  if not noAbsolutePaths(): 
    # compute include paths:
    includeCmd = cc[c].includeCmd & quoteIfContainsWhite(libpath)

    for includeDir in items(cIncludes):
      includeCmd.add([cc[c].includeCmd, includeDir.quoteIfContainsWhite])

    compilePattern = JoinPath(ccompilerpath, exe)
  else: 
    includeCmd = ""
    compilePattern = cc[c].compilerExe
  
  var cfile = if noAbsolutePaths(): extractFileName(cfilename) 
              else: cfilename
  var objfile = if not isExternal or noAbsolutePaths(): 
                  toObjFile(cfile) 
                else: 
                  completeCFilePath(toObjFile(cfile))
  cfile = quoteIfContainsWhite(AddFileExt(cfile, cExt))
  objfile = quoteIfContainsWhite(objfile)
  result = quoteIfContainsWhite(compilePattern % [
    "file", cfile, "objfile", objfile, "options", options, 
    "include", includeCmd, "nimrod", getPrefixDir(), "lib", libpath])
  add(result, ' ')
  addf(result, cc[c].compileTmpl, [
    "file", cfile, "objfile", objfile, 
    "options", options, "include", includeCmd, 
    "nimrod", quoteIfContainsWhite(getPrefixDir()), 
    "lib", quoteIfContainsWhite(libpath)])

proc footprint(filename: string): TCrc32 =
  result = crcFromFile(filename) ><
      platform.OS[targetOS].name ><
      platform.CPU[targetCPU].name ><
      extccomp.CC[extccomp.ccompiler].name ><
      getCompileCFileCmd(filename, true)

proc externalFileChanged(filename: string): bool = 
  var crcFile = toGeneratedFile(filename.withPackageName, "crc")
  var currentCrc = int(footprint(filename))
  var f: TFile
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

proc CompileCFile(list: TLinkedList, script: var PRope, cmds: var TStringSeq, 
                  isExternal: bool) = 
  var it = PStrEntry(list.head)
  while it != nil: 
    inc(fileCounter)          # call the C compiler for the .c file:
    var compileCmd = getCompileCFileCmd(it.data, isExternal)
    if optCompileOnly notin gGlobalOptions: 
      add(cmds, compileCmd)
    if optGenScript in gGlobalOptions: 
      app(script, compileCmd)
      app(script, tnl)
    it = PStrEntry(it.next)

proc CallCCompiler*(projectfile: string) =
  var 
    linkCmd, buildgui, builddll: string
  if gGlobalOptions * {optCompileOnly, optGenScript} == {optCompileOnly}: 
    return # speed up that call if only compiling and no script shall be
           # generated
  fileCounter = 0
  var c = ccompiler
  var script: PRope = nil
  var cmds: TStringSeq = @[]
  CompileCFile(toCompile, script, cmds, false)
  CompileCFile(externalToCompile, script, cmds, true)
  if optCompileOnly notin gGlobalOptions: 
    if gNumberOfProcessors == 0: gNumberOfProcessors = countProcessors()
    var res = 0
    if gNumberOfProcessors <= 1: 
      for i in countup(0, high(cmds)): res = max(execCmd(cmds[i]), res)
    elif optListCmd in gGlobalOptions or gVerbosity > 0: 
      res = execProcesses(cmds, {poEchoCmd, poUseShell, poParentStreams}, 
                          gNumberOfProcessors)
    else: 
      res = execProcesses(cmds, {poUseShell, poParentStreams}, 
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
      add(objfiles, quoteIfContainsWhite(
          addFileExt(objFile, cc[ccompiler].objExt)))
      it = PStrEntry(it.next)

    if optGenStaticLib in gGlobalOptions:
      linkcmd = cc[c].buildLib % ["libfile", (libNameTmpl() % gProjectName),
                                  "objfiles", objfiles]
      if optCompileOnly notin gGlobalOptions: execExternalProgram(linkCmd)
    else:
      var linkerExe = getConfigVar(c, ".linkerexe")
      if len(linkerExe) == 0: linkerExe = cc[c].linkerExe
      if needsExeExt(): linkerExe = addFileExt(linkerExe, "exe")
      if noAbsolutePaths(): linkCmd = quoteIfContainsWhite(linkerExe)
      else: linkCmd = quoteIfContainsWhite(JoinPath(ccompilerpath, linkerExe))
      if optGenGuiApp in gGlobalOptions: buildGui = cc[c].buildGui
      else: buildGui = ""
      var exefile: string
      if optGenDynLib in gGlobalOptions:
        exefile = platform.os[targetOS].dllFrmt % splitFile(projectFile).name
        buildDll = cc[c].buildDll
      else:
        exefile = splitFile(projectFile).name & platform.os[targetOS].exeExt
        buildDll = ""
      if options.outFile.len > 0: 
        exefile = options.outFile
      if not noAbsolutePaths():
        exefile = joinPath(splitFile(projectFile).dir, exefile)
      exefile = quoteIfContainsWhite(exefile)
      let linkOptions = getLinkOptions()
      linkCmd = quoteIfContainsWhite(linkCmd % ["builddll", builddll,
          "buildgui", buildgui, "options", linkOptions, "objfiles", objfiles,
          "exefile", exefile, "nimrod", getPrefixDir(), "lib", libpath])
      linkCmd.add ' '
      addf(linkCmd, cc[c].linkTmpl, ["builddll", builddll,
          "buildgui", buildgui, "options", linkOptions,
          "objfiles", objfiles, "exefile", exefile,
          "nimrod", quoteIfContainsWhite(getPrefixDir()),
          "lib", quoteIfContainsWhite(libpath)])
      if optCompileOnly notin gGlobalOptions: execExternalProgram(linkCmd)
  else:
    linkCmd = ""
  if optGenScript in gGlobalOptions:
    app(script, linkCmd)
    app(script, tnl)
    generateScript(projectFile, script)

proc genMappingFiles(list: TLinkedList): PRope = 
  var it = PStrEntry(list.head)
  while it != nil: 
    appf(result, "--file:r\"$1\"$N", [toRope(AddFileExt(it.data, cExt))])
    it = PStrEntry(it.next)

proc writeMapping*(gSymbolMapping: PRope) = 
  if optGenMapping notin gGlobalOptions: return 
  var code = toRope("[C_Files]\n")
  app(code, genMappingFiles(toCompile))
  app(code, genMappingFiles(externalToCompile))
  app(code, "\n[C_Compiler]\nFlags=")
  app(code, strutils.escape(getCompileOptions()))
  
  app(code, "\n[Linker]\nFlags=")
  app(code, strutils.escape(getLinkOptions()))

  app(code, "\n[Environment]\nlibpath=")
  app(code, strutils.escape(libpath))
  
  appf(code, "\n[Symbols]$n$1", [gSymbolMapping])
  WriteRope(code, joinPath(gProjectPath, "mapping.txt"))
  
