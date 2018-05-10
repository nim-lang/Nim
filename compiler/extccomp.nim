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
  ropes, os, strutils, osproc, platform, condsyms, options, msgs,
  configuration, std / sha1, streams

#from debuginfo import writeDebugInfo

type
  TSystemCC* = enum
    ccNone, ccGcc, ccLLVM_Gcc, ccCLang, ccLcc, ccBcc, ccDmc, ccWcc, ccVcc,
    ccTcc, ccPcc, ccUcc, ccIcl, ccIcc
  TInfoCCProp* = enum         # properties of the C compiler:
    hasSwitchRange,           # CC allows ranges in switch statements (GNU C)
    hasComputedGoto,          # CC has computed goto (GNU C extension)
    hasCpp,                   # CC is/contains a C++ compiler
    hasAssume,                # CC has __assume (Visual C extension)
    hasGcGuard,               # CC supports GC_GUARD to keep stack roots
    hasGnuAsm,                # CC's asm uses the absurd GNU assembler syntax
    hasDeclspec,              # CC has __declspec(X)
    hasAttribute,             # CC has __attribute__((X))
  TInfoCCProps* = set[TInfoCCProp]
  TInfoCC* = tuple[
    name: string,        # the short name of the compiler
    objExt: string,      # the compiler's object file extension
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
    props: TInfoCCProps] # properties of the C compiler


# Configuration settings for various compilers.
# When adding new compilers, the cmake sources could be a good reference:
# http://cmake.org/gitweb?p=cmake.git;a=tree;f=Modules/Platform;

template compiler(name, settings: untyped): untyped =
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
    props: {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard, hasGnuAsm,
            hasAttribute})

# LLVM Frontend for GCC/G++
compiler llvmGcc:
  result = gcc() # Uses settings from GCC

  result.name = "llvm_gcc"
  result.compilerExe = "llvm-gcc"
  result.cppCompiler = "llvm-g++"
  when defined(macosx):
    # OS X has no 'llvm-ar' tool:
    result.buildLib = "ar rcs $libfile $objfiles"
  else:
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
    debug: " /RTC1 /Z7 ",
    pic: "",
    asmStmtFrmt: "__asm{$n$1$n}$n",
    structStmtFmt: "$3$n$1 $2",
    props: {hasCpp, hasAssume, hasDeclspec})

# Intel C/C++ Compiler
compiler icl:
  result = vcc()
  result.name = "icl"
  result.compilerExe = "icl"
  result.linkerExe = "icl"

# Intel compilers try to imitate the native ones (gcc and msvc)
compiler icc:
  result = gcc()
  result.name = "icc"
  result.compilerExe = "icc"
  result.linkerExe = "icc"

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
    props: {})

# Borland C Compiler
compiler bcc:
  result = (
    name: "bcc",
    objExt: "obj",
    optSpeed: " -O3 -6 ",
    optSize: " -O1 -6 ",
    compilerExe: "bcc32c",
    cppCompiler: "cpp32c",
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
    props: {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard,
            hasAttribute})


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
    buildGui: "-Wl,-subsystem=gui",
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
    icc()]

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

type
  CfileFlag* {.pure.} = enum
    Cached,    ## no need to recompile this time
    External   ## file was introduced via .compile pragma

  Cfile* = object
    cname*, obj*: string
    flags*: set[CFileFlag]
  CfileList = seq[Cfile]

var
  externalToLink: seq[string] = @[] # files to link in addition to the file
                                    # we compiled
  linkOptionsCmd: string = ""
  compileOptionsCmd: seq[string] = @[]
  linkOptions: string = ""
  compileOptions: string = ""
  ccompilerpath: string = ""
  toCompile: CfileList = @[]

proc nameToCC*(name: string): TSystemCC =
  ## Returns the kind of compiler referred to by `name`, or ccNone
  ## if the name doesn't refer to any known compiler.
  for i in countup(succ(ccNone), high(TSystemCC)):
    if cmpIgnoreStyle(name, CC[i].name) == 0:
      return i
  result = ccNone

proc getConfigVar(conf: ConfigRef; c: TSystemCC, suffix: string): string =
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
    result = getConfigVar(conf, fullCCname)
    if result.len == 0:
      # not overriden for this cross compilation setting?
      result = getConfigVar(conf, CC[c].name & fullSuffix)
  else:
    result = getConfigVar(conf, CC[c].name & fullSuffix)

proc setCC*(conf: ConfigRef; ccname: string; info: TLineInfo) =
  cCompiler = nameToCC(ccname)
  if cCompiler == ccNone:
    localError(conf, info, "unknown C compiler: '$1'" % ccname)
  compileOptions = getConfigVar(conf, cCompiler, ".options.always")
  linkOptions = ""
  ccompilerpath = getConfigVar(conf, cCompiler, ".path")
  for i in countup(low(CC), high(CC)): undefSymbol(conf.symbols, CC[i].name)
  defineSymbol(conf.symbols, CC[cCompiler].name)

proc addOpt(dest: var string, src: string) =
  if len(dest) == 0 or dest[len(dest)-1] != ' ': add(dest, " ")
  add(dest, src)

proc addLinkOption*(conf: ConfigRef; option: string) =
  addOpt(linkOptions, option)

proc addCompileOption*(conf: ConfigRef; option: string) =
  if strutils.find(compileOptions, option, 0) < 0:
    addOpt(compileOptions, option)

proc addLinkOptionCmd*(conf: ConfigRef; option: string) =
  addOpt(linkOptionsCmd, option)

proc addCompileOptionCmd*(conf: ConfigRef; option: string) =
  compileOptionsCmd.add(option)

proc initVars*(conf: ConfigRef) =
  # we need to define the symbol here, because ``CC`` may have never been set!
  for i in countup(low(CC), high(CC)): undefSymbol(conf.symbols, CC[i].name)
  defineSymbol(conf.symbols, CC[cCompiler].name)
  addCompileOption(conf, getConfigVar(conf, cCompiler, ".options.always"))
  #addLinkOption(getConfigVar(cCompiler, ".options.linker"))
  if len(ccompilerpath) == 0:
    ccompilerpath = getConfigVar(conf, cCompiler, ".path")

proc completeCFilePath*(conf: ConfigRef; cfile: string, createSubDir: bool = true): string =
  result = completeGeneratedFilePath(conf, cfile, createSubDir)

proc toObjFile*(conf: ConfigRef; filename: string): string =
  # Object file for compilation
  #if filename.endsWith(".cpp"):
  #  result = changeFileExt(filename, "cpp." & CC[cCompiler].objExt)
  #else:
  result = changeFileExt(filename, CC[cCompiler].objExt)

proc addFileToCompile*(conf: ConfigRef; cf: Cfile) =
  toCompile.add(cf)

proc resetCompilationLists*(conf: ConfigRef) =
  toCompile.setLen 0
  ## XXX: we must associate these with their originating module
  # when the module is loaded/unloaded it adds/removes its items
  # That's because we still need to hash check the external files
  # Maybe we can do that in checkDep on the other hand?
  externalToLink.setLen 0

proc addExternalFileToLink*(conf: ConfigRef; filename: string) =
  externalToLink.insert(filename, 0)

proc execWithEcho(conf: ConfigRef; cmd: string, msg = hintExecuting): int =
  rawMessage(conf, msg, cmd)
  result = execCmd(cmd)

proc execExternalProgram*(conf: ConfigRef; cmd: string, msg = hintExecuting) =
  if execWithEcho(conf, cmd, msg) != 0:
    rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
      cmd)

proc generateScript(conf: ConfigRef; projectFile: string, script: Rope) =
  let (dir, name, ext) = splitFile(projectFile)
  writeRope(script, getNimcacheDir(conf) / addFileExt("compile_" & name,
                                     platform.OS[targetOS].scriptExt))
  copyFile(libpath / "nimbase.h", getNimcacheDir(conf) / "nimbase.h")

proc getOptSpeed(conf: ConfigRef; c: TSystemCC): string =
  result = getConfigVar(conf, c, ".options.speed")
  if result == "":
    result = CC[c].optSpeed   # use default settings from this file

proc getDebug(conf: ConfigRef; c: TSystemCC): string =
  result = getConfigVar(conf, c, ".options.debug")
  if result == "":
    result = CC[c].debug      # use default settings from this file

proc getOptSize(conf: ConfigRef; c: TSystemCC): string =
  result = getConfigVar(conf, c, ".options.size")
  if result == "":
    result = CC[c].optSize    # use default settings from this file

proc noAbsolutePaths(conf: ConfigRef): bool {.inline.} =
  # We used to check current OS != specified OS, but this makes no sense
  # really: Cross compilation from Linux to Linux for example is entirely
  # reasonable.
  # `optGenMapping` is included here for niminst.
  result = gGlobalOptions * {optGenScript, optGenMapping} != {}

proc cFileSpecificOptions(conf: ConfigRef; cfilename: string): string =
  result = compileOptions
  for option in compileOptionsCmd:
    if strutils.find(result, option, 0) < 0:
      addOpt(result, option)

  let trunk = splitFile(cfilename).name
  if optCDebug in gGlobalOptions:
    let key = trunk & ".debug"
    if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))
    else: addOpt(result, getDebug(conf, cCompiler))
  if optOptimizeSpeed in gOptions:
    let key = trunk & ".speed"
    if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))
    else: addOpt(result, getOptSpeed(conf, cCompiler))
  elif optOptimizeSize in gOptions:
    let key = trunk & ".size"
    if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))
    else: addOpt(result, getOptSize(conf, cCompiler))
  let key = trunk & ".always"
  if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))

proc getCompileOptions(conf: ConfigRef): string =
  result = cFileSpecificOptions(conf, "__dummy__")

proc getLinkOptions(conf: ConfigRef): string =
  result = linkOptions & " " & linkOptionsCmd & " "
  for linkedLib in items(cLinkedLibs):
    result.add(CC[cCompiler].linkLibCmd % linkedLib.quoteShell)
  for libDir in items(cLibs):
    result.add(join([CC[cCompiler].linkDirCmd, libDir.quoteShell]))

proc needsExeExt(conf: ConfigRef): bool {.inline.} =
  result = (optGenScript in gGlobalOptions and targetOS == osWindows) or
           (platform.hostOS == osWindows)

proc getCompilerExe(conf: ConfigRef; compiler: TSystemCC; cfile: string): string =
  result = if gCmd == cmdCompileToCpp and not cfile.endsWith(".c"):
             CC[compiler].cppCompiler
           else:
             CC[compiler].compilerExe
  if result.len == 0:
    rawMessage(conf, errGenerated,
      "Compiler '$1' doesn't support the requested target" %
      CC[compiler].name)

proc getLinkerExe(conf: ConfigRef; compiler: TSystemCC): string =
  result = if CC[compiler].linkerExe.len > 0: CC[compiler].linkerExe
           elif gMixedMode and gCmd != cmdCompileToCpp: CC[compiler].cppCompiler
           else: getCompilerExe(conf, compiler, "")

proc getCompileCFileCmd*(conf: ConfigRef; cfile: Cfile): string =
  var c = cCompiler
  var options = cFileSpecificOptions(conf, cfile.cname)
  var exe = getConfigVar(conf, c, ".exe")
  if exe.len == 0: exe = getCompilerExe(conf, c, cfile.cname)

  if needsExeExt(conf): exe = addFileExt(exe, "exe")
  if optGenDynLib in gGlobalOptions and
      ospNeedsPIC in platform.OS[targetOS].props:
    add(options, ' ' & CC[c].pic)

  var includeCmd, compilePattern: string
  if not noAbsolutePaths(conf):
    # compute include paths:
    includeCmd = CC[c].includeCmd & quoteShell(libpath)

    for includeDir in items(cIncludes):
      includeCmd.add(join([CC[c].includeCmd, includeDir.quoteShell]))

    compilePattern = joinPath(ccompilerpath, exe)
  else:
    includeCmd = ""
    compilePattern = getCompilerExe(conf, c, cfile.cname)

  var cf = if noAbsolutePaths(conf): extractFilename(cfile.cname)
           else: cfile.cname

  var objfile =
    if cfile.obj.len == 0:
      if not cfile.flags.contains(CfileFlag.External) or noAbsolutePaths(conf):
        toObjFile(conf, cf)
      else:
        completeCFilePath(conf, toObjFile(conf, cf))
    elif noAbsolutePaths(conf):
      extractFilename(cfile.obj)
    else:
      cfile.obj

  objfile = quoteShell(objfile)
  cf = quoteShell(cf)
  result = quoteShell(compilePattern % [
    "file", cf, "objfile", objfile, "options", options,
    "include", includeCmd, "nim", getPrefixDir(conf),
    "nim", getPrefixDir(conf), "lib", libpath])
  add(result, ' ')
  addf(result, CC[c].compileTmpl, [
    "file", cf, "objfile", objfile,
    "options", options, "include", includeCmd,
    "nim", quoteShell(getPrefixDir(conf)),
    "nim", quoteShell(getPrefixDir(conf)),
    "lib", quoteShell(libpath)])

proc footprint(conf: ConfigRef; cfile: Cfile): SecureHash =
  result = secureHash(
    $secureHashFile(cfile.cname) &
    platform.OS[targetOS].name &
    platform.CPU[targetCPU].name &
    extccomp.CC[extccomp.cCompiler].name &
    getCompileCFileCmd(conf, cfile))

proc externalFileChanged(conf: ConfigRef; cfile: Cfile): bool =
  if gCmd notin {cmdCompileToC, cmdCompileToCpp, cmdCompileToOC, cmdCompileToLLVM}:
    return false

  var hashFile = toGeneratedFile(conf, cfile.cname.withPackageName, "sha1")
  var currentHash = footprint(conf, cfile)
  var f: File
  if open(f, hashFile, fmRead):
    let oldHash = parseSecureHash(f.readLine())
    close(f)
    result = oldHash != currentHash
  else:
    result = true
  if result:
    if open(f, hashFile, fmWrite):
      f.writeLine($currentHash)
      close(f)

proc addExternalFileToCompile*(conf: ConfigRef; c: var Cfile) =
  if optForceFullMake notin gGlobalOptions and not externalFileChanged(conf, c):
    c.flags.incl CfileFlag.Cached
  toCompile.add(c)

proc addExternalFileToCompile*(conf: ConfigRef; filename: string) =
  var c = Cfile(cname: filename,
    obj: toObjFile(conf, completeCFilePath(conf, changeFileExt(filename, ""), false)),
    flags: {CfileFlag.External})
  addExternalFileToCompile(conf, c)

proc compileCFile(conf: ConfigRef; list: CFileList, script: var Rope, cmds: var TStringSeq,
                  prettyCmds: var TStringSeq) =
  for it in list:
    # call the C compiler for the .c file:
    if it.flags.contains(CfileFlag.Cached): continue
    var compileCmd = getCompileCFileCmd(conf, it)
    if optCompileOnly notin gGlobalOptions:
      add(cmds, compileCmd)
      let (_, name, _) = splitFile(it.cname)
      add(prettyCmds, "CC: " & name)
    if optGenScript in gGlobalOptions:
      add(script, compileCmd)
      add(script, tnl)

proc getLinkCmd(conf: ConfigRef; projectfile, objfiles: string): string =
  if optGenStaticLib in gGlobalOptions:
    var libname: string
    if options.outFile.len > 0:
      libname = options.outFile.expandTilde
      if not libname.isAbsolute():
        libname = getCurrentDir() / libname
    else:
      libname = (libNameTmpl() % splitFile(gProjectName).name)
    result = CC[cCompiler].buildLib % ["libfile", libname,
                                       "objfiles", objfiles]
  else:
    var linkerExe = getConfigVar(conf, cCompiler, ".linkerexe")
    if len(linkerExe) == 0: linkerExe = getLinkerExe(conf, cCompiler)
    # bug #6452: We must not use ``quoteShell`` here for ``linkerExe``
    if needsExeExt(conf): linkerExe = addFileExt(linkerExe, "exe")
    if noAbsolutePaths(conf): result = linkerExe
    else: result = joinPath(ccompilerpath, linkerExe)
    let buildgui = if optGenGuiApp in gGlobalOptions: CC[cCompiler].buildGui
                   else: ""
    var exefile, builddll: string
    if optGenDynLib in gGlobalOptions:
      exefile = platform.OS[targetOS].dllFrmt % splitFile(projectfile).name
      builddll = CC[cCompiler].buildDll
    else:
      exefile = splitFile(projectfile).name & platform.OS[targetOS].exeExt
      builddll = ""
    if options.outFile.len > 0:
      exefile = options.outFile.expandTilde
      if not exefile.isAbsolute():
        exefile = getCurrentDir() / exefile
    if not noAbsolutePaths(conf):
      if not exefile.isAbsolute():
        exefile = joinPath(splitFile(projectfile).dir, exefile)
    when false:
      if optCDebug in gGlobalOptions:
        writeDebugInfo(exefile.changeFileExt("ndb"))
    exefile = quoteShell(exefile)
    let linkOptions = getLinkOptions(conf) & " " &
                      getConfigVar(conf, cCompiler, ".options.linker")
    var linkTmpl = getConfigVar(conf, cCompiler, ".linkTmpl")
    if linkTmpl.len == 0:
      linkTmpl = CC[cCompiler].linkTmpl
    result = quoteShell(result % ["builddll", builddll,
        "buildgui", buildgui, "options", linkOptions, "objfiles", objfiles,
        "exefile", exefile, "nim", getPrefixDir(conf), "lib", libpath])
    result.add ' '
    addf(result, linkTmpl, ["builddll", builddll,
        "buildgui", buildgui, "options", linkOptions,
        "objfiles", objfiles, "exefile", exefile,
        "nim", quoteShell(getPrefixDir(conf)),
        "lib", quoteShell(libpath)])

template tryExceptOSErrorMessage(conf: ConfigRef; errorPrefix: string = "", body: untyped): typed =
  try:
    body
  except OSError:
    let ose = (ref OSError)(getCurrentException())
    if errorPrefix.len > 0:
      rawMessage(conf, errGenerated, errorPrefix & " " & ose.msg & " " & $ose.errorCode)
    else:
      rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
        (ose.msg & " " & $ose.errorCode))
    raise

proc execLinkCmd(conf: ConfigRef; linkCmd: string) =
  tryExceptOSErrorMessage(conf, "invocation of external linker program failed."):
    execExternalProgram(conf, linkCmd,
      if optListCmd in gGlobalOptions or gVerbosity > 1: hintExecuting else: hintLinking)

proc execCmdsInParallel(conf: ConfigRef; cmds: seq[string]; prettyCb: proc (idx: int)) =
  let runCb = proc (idx: int, p: Process) =
    let exitCode = p.peekExitCode
    if exitCode != 0:
      rawMessage(conf, errGenerated, "execution of an external compiler program '" &
        cmds[idx] & "' failed with exit code: " & $exitCode & "\n\n" &
        p.outputStream.readAll.strip)
  if gNumberOfProcessors == 0: gNumberOfProcessors = countProcessors()
  var res = 0
  if gNumberOfProcessors <= 1:
    for i in countup(0, high(cmds)):
      tryExceptOSErrorMessage(conf, "invocation of external compiler program failed."):
        res = execWithEcho(conf, cmds[i])
      if res != 0:
        rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
          cmds[i])
  else:
    tryExceptOSErrorMessage(conf, "invocation of external compiler program failed."):
      if optListCmd in gGlobalOptions or gVerbosity > 1:
        res = execProcesses(cmds, {poEchoCmd, poStdErrToStdOut, poUsePath},
                            gNumberOfProcessors, afterRunEvent=runCb)
      elif gVerbosity == 1:
        res = execProcesses(cmds, {poStdErrToStdOut, poUsePath},
                            gNumberOfProcessors, prettyCb, afterRunEvent=runCb)
      else:
        res = execProcesses(cmds, {poStdErrToStdOut, poUsePath},
                            gNumberOfProcessors, afterRunEvent=runCb)
  if res != 0:
    if gNumberOfProcessors <= 1:
      rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
        cmds.join())

proc callCCompiler*(conf: ConfigRef; projectfile: string) =
  var
    linkCmd: string
  if gGlobalOptions * {optCompileOnly, optGenScript} == {optCompileOnly}:
    return # speed up that call if only compiling and no script shall be
           # generated
  #var c = cCompiler
  var script: Rope = nil
  var cmds: TStringSeq = @[]
  var prettyCmds: TStringSeq = @[]
  let prettyCb = proc (idx: int) =
    echo prettyCmds[idx]
  compileCFile(conf, toCompile, script, cmds, prettyCmds)
  if optCompileOnly notin gGlobalOptions:
    execCmdsInParallel(conf, cmds, prettyCb)
  if optNoLinking notin gGlobalOptions:
    # call the linker:
    var objfiles = ""
    for it in externalToLink:
      let objFile = if noAbsolutePaths(conf): it.extractFilename else: it
      add(objfiles, ' ')
      add(objfiles, quoteShell(
          addFileExt(objFile, CC[cCompiler].objExt)))
    for x in toCompile:
      let objFile = if noAbsolutePaths(conf): x.obj.extractFilename else: x.obj
      add(objfiles, ' ')
      add(objfiles, quoteShell(objFile))

    linkCmd = getLinkCmd(conf, projectfile, objfiles)
    if optCompileOnly notin gGlobalOptions:
      execLinkCmd(conf, linkCmd)
  else:
    linkCmd = ""
  if optGenScript in gGlobalOptions:
    add(script, linkCmd)
    add(script, tnl)
    generateScript(conf, projectfile, script)

#from json import escapeJson
import json

proc writeJsonBuildInstructions*(conf: ConfigRef; projectfile: string) =
  template lit(x: untyped) = f.write x
  template str(x: untyped) =
    when compiles(escapeJson(x, buf)):
      buf.setLen 0
      escapeJson(x, buf)
      f.write buf
    else:
      f.write escapeJson(x)

  proc cfiles(conf: ConfigRef; f: File; buf: var string; clist: CfileList, isExternal: bool) =
    var pastStart = false
    for it in clist:
      if CfileFlag.Cached in it.flags: continue
      let compileCmd = getCompileCFileCmd(conf, it)
      if pastStart: lit "],\L"
      lit "["
      str it.cname
      lit ", "
      str compileCmd
      pastStart = true
    lit "]\L"

  proc linkfiles(conf: ConfigRef; f: File; buf, objfiles: var string; clist: CfileList;
                 llist: seq[string]) =
    var pastStart = false
    for it in llist:
      let objfile = if noAbsolutePaths(conf): it.extractFilename
                    else: it
      let objstr = addFileExt(objfile, CC[cCompiler].objExt)
      add(objfiles, ' ')
      add(objfiles, objstr)
      if pastStart: lit ",\L"
      str objstr
      pastStart = true

    for it in clist:
      let objstr = quoteShell(it.obj)
      add(objfiles, ' ')
      add(objfiles, objstr)
      if pastStart: lit ",\L"
      str objstr
      pastStart = true
    lit "\L"

  var buf = newStringOfCap(50)

  let file = projectfile.splitFile.name
  let jsonFile = toGeneratedFile(conf, file, "json")

  var f: File
  if open(f, jsonFile, fmWrite):
    lit "{\"compile\":[\L"
    cfiles(conf, f, buf, toCompile, false)
    lit "],\L\"link\":[\L"
    var objfiles = ""
    # XXX add every file here that is to link
    linkfiles(conf, f, buf, objfiles, toCompile, externalToLink)

    lit "],\L\"linkcmd\": "
    str getLinkCmd(conf, projectfile, objfiles)
    lit "\L}\L"
    close(f)

proc runJsonBuildInstructions*(conf: ConfigRef; projectfile: string) =
  let file = projectfile.splitFile.name
  let jsonFile = toGeneratedFile(conf, file, "json")
  try:
    let data = json.parseFile(jsonFile)
    let toCompile = data["compile"]
    doAssert toCompile.kind == JArray
    var cmds: TStringSeq = @[]
    var prettyCmds: TStringSeq = @[]
    for c in toCompile:
      doAssert c.kind == JArray
      doAssert c.len >= 2

      add(cmds, c[1].getStr)
      let (_, name, _) = splitFile(c[0].getStr)
      add(prettyCmds, "CC: " & name)

    let prettyCb = proc (idx: int) =
      echo prettyCmds[idx]
    execCmdsInParallel(conf, cmds, prettyCb)

    let linkCmd = data["linkcmd"]
    doAssert linkCmd.kind == JString
    execLinkCmd(conf, linkCmd.getStr)
  except:
    echo getCurrentException().getStackTrace()
    quit "error evaluating JSON file: " & jsonFile

proc genMappingFiles(conf: ConfigRef; list: CFileList): Rope =
  for it in list:
    addf(result, "--file:r\"$1\"$N", [rope(it.cname)])

proc writeMapping*(conf: ConfigRef; symbolMapping: Rope) =
  if optGenMapping notin gGlobalOptions: return
  var code = rope("[C_Files]\n")
  add(code, genMappingFiles(conf, toCompile))
  add(code, "\n[C_Compiler]\nFlags=")
  add(code, strutils.escape(getCompileOptions(conf)))

  add(code, "\n[Linker]\nFlags=")
  add(code, strutils.escape(getLinkOptions(conf) & " " &
                            getConfigVar(conf, cCompiler, ".options.linker")))

  add(code, "\n[Environment]\nlibpath=")
  add(code, strutils.escape(libpath))

  addf(code, "\n[Symbols]$n$1", [symbolMapping])
  writeRope(code, joinPath(gProjectPath, "mapping.txt"))
