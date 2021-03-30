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
# from a lineinfos file, to provide generalized procedures to compile
# nim files.

import ropes, platform, condsyms, options, msgs, lineinfos, pathutils

import std/[os, strutils, osproc, sha1, streams, sequtils, times, strtabs, json]

type
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
    produceAsm: string,  # Format how to produce assembler listings
    cppXsupport: string, # what to do to enable C++X support
    props: TInfoCCProps] # properties of the C compiler


# Configuration settings for various compilers.
# When adding new compilers, the cmake sources could be a good reference:
# http://cmake.org/gitweb?p=cmake.git;a=tree;f=Modules/Platform;

template compiler(name, settings: untyped): untyped =
  proc name: TInfoCC {.compileTime.} = settings

const
  gnuAsmListing = "-Wa,-acdl=$asmfile -g -fverbose-asm -masm=intel"

# GNU C and C++ Compiler
compiler gcc:
  result = (
    name: "gcc",
    objExt: "o",
    optSpeed: " -O3 -fno-ident",
    optSize: " -Os -fno-ident",
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
    produceAsm: gnuAsmListing,
    cppXsupport: "-std=gnu++14 -funsigned-char",
    props: {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard, hasGnuAsm,
            hasAttribute})

# GNU C and C++ Compiler
compiler nintendoSwitchGCC:
  result = (
    name: "switch_gcc",
    objExt: "o",
    optSpeed: " -O3 ",
    optSize: " -Os ",
    compilerExe: "aarch64-none-elf-gcc",
    cppCompiler: "aarch64-none-elf-g++",
    compileTmpl: "-w -MMD -MP -MF $dfile -c $options $include -o $objfile $file",
    buildGui: " -mwindows",
    buildDll: " -shared",
    buildLib: "aarch64-none-elf-gcc-ar rcs $libfile $objfiles",
    linkerExe: "aarch64-none-elf-gcc",
    linkTmpl: "$buildgui $builddll -Wl,-Map,$mapfile -o $exefile $objfiles $options",
    includeCmd: " -I",
    linkDirCmd: " -L",
    linkLibCmd: " -l$1",
    debug: "",
    pic: "-fPIE",
    asmStmtFrmt: "asm($1);$n",
    structStmtFmt: "$1 $3 $2 ", # struct|union [packed] $name
    produceAsm: gnuAsmListing,
    cppXsupport: "-std=gnu++14 -funsigned-char",
    props: {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard, hasGnuAsm,
            hasAttribute})

# LLVM Frontend for GCC/G++
compiler llvmGcc:
  result = gcc() # Uses settings from GCC

  result.name = "llvm_gcc"
  result.compilerExe = "llvm-gcc"
  result.cppCompiler = "llvm-g++"
  when defined(macosx) or defined(openbsd):
    # `llvm-ar` not available
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
    optSpeed: " /Ogityb2 ",
    optSize: " /O1 ",
    compilerExe: "cl",
    cppCompiler: "cl",
    compileTmpl: "/c$vccplatform $options $include /nologo /Fo$objfile $file",
    buildGui: " /SUBSYSTEM:WINDOWS user32.lib ",
    buildDll: " /LD",
    buildLib: "lib /OUT:$libfile $objfiles",
    linkerExe: "cl",
    linkTmpl: "$builddll$vccplatform /Fe$exefile $objfiles $buildgui /nologo $options",
    includeCmd: " /I",
    linkDirCmd: " /LIBPATH:",
    linkLibCmd: " $1.lib",
    debug: " /RTC1 /Z7 ",
    pic: "",
    asmStmtFrmt: "__asm{$n$1$n}$n",
    structStmtFmt: "$3$n$1 $2",
    produceAsm: "/Fa$asmfile",
    cppXsupport: "",
    props: {hasCpp, hasAssume, hasDeclspec})

compiler clangcl:
  result = vcc()
  result.name = "clang_cl"
  result.compilerExe = "clang-cl"
  result.cppCompiler = "clang-cl"
  result.linkerExe = "clang-cl"
  result.linkTmpl = "-fuse-ld=lld " & result.linkTmpl

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
    produceAsm: "",
    cppXsupport: "",
    props: {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard,
            hasAttribute})

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
    asmStmtFrmt: "asm($1);$n",
    structStmtFmt: "$1 $2",
    produceAsm: gnuAsmListing,
    cppXsupport: "",
    props: {hasSwitchRange, hasComputedGoto, hasGnuAsm})

# Your C Compiler
compiler envcc:
  result = (
    name: "env",
    objExt: "o",
    optSpeed: " -O3 ",
    optSize: " -O1 ",
    compilerExe: "",
    cppCompiler: "",
    compileTmpl: "-c $ccenvflags $options $include -o $objfile $file",
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
    produceAsm: "",
    cppXsupport: "",
    props: {hasGnuAsm})

const
  CC*: array[succ(low(TSystemCC))..high(TSystemCC), TInfoCC] = [
    gcc(),
    nintendoSwitchGCC(),
    llvmGcc(),
    clang(),
    bcc(),
    vcc(),
    tcc(),
    envcc(),
    icl(),
    icc(),
    clangcl()]

  hExt* = ".h"

proc nameToCC*(name: string): TSystemCC =
  ## Returns the kind of compiler referred to by `name`, or ccNone
  ## if the name doesn't refer to any known compiler.
  for i in succ(ccNone)..high(TSystemCC):
    if cmpIgnoreStyle(name, CC[i].name) == 0:
      return i
  result = ccNone

proc listCCnames(): string =
  result = ""
  for i in succ(ccNone)..high(TSystemCC):
    if i > succ(ccNone): result.add ", "
    result.add CC[i].name

proc isVSCompatible*(conf: ConfigRef): bool =
  return conf.cCompiler == ccVcc or
          conf.cCompiler == ccClangCl or
          (conf.cCompiler == ccIcl and conf.target.hostOS in osDos..osWindows)

proc getConfigVar(conf: ConfigRef; c: TSystemCC, suffix: string): string =
  # use ``cpu.os.cc`` for cross compilation, unless ``--compileOnly`` is given
  # for niminst support
  var fullSuffix = suffix
  case conf.backend
  of backendCpp, backendJs, backendObjc: fullSuffix = "." & $conf.backend & suffix
  of backendC: discard
  of backendInvalid:
    # during parsing of cfg files; we don't know the backend yet, no point in
    # guessing wrong thing
    return ""

  if (conf.target.hostOS != conf.target.targetOS or conf.target.hostCPU != conf.target.targetCPU) and
      optCompileOnly notin conf.globalOptions:
    let fullCCname = platform.CPU[conf.target.targetCPU].name & '.' &
                     platform.OS[conf.target.targetOS].name & '.' &
                     CC[c].name & fullSuffix
    result = getConfigVar(conf, fullCCname)
    if result.len == 0:
      # not overridden for this cross compilation setting?
      result = getConfigVar(conf, CC[c].name & fullSuffix)
  else:
    result = getConfigVar(conf, CC[c].name & fullSuffix)

proc setCC*(conf: ConfigRef; ccname: string; info: TLineInfo) =
  conf.cCompiler = nameToCC(ccname)
  if conf.cCompiler == ccNone:
    localError(conf, info, "unknown C compiler: '$1'. Available options are: $2" % [ccname, listCCnames()])
  conf.compileOptions = getConfigVar(conf, conf.cCompiler, ".options.always")
  conf.linkOptions = ""
  conf.cCompilerPath = getConfigVar(conf, conf.cCompiler, ".path")
  for c in CC: undefSymbol(conf.symbols, c.name)
  defineSymbol(conf.symbols, CC[conf.cCompiler].name)

proc addOpt(dest: var string, src: string) =
  if dest.len == 0 or dest[^1] != ' ': dest.add(" ")
  dest.add(src)

proc addLinkOption*(conf: ConfigRef; option: string) =
  addOpt(conf.linkOptions, option)

proc addCompileOption*(conf: ConfigRef; option: string) =
  if strutils.find(conf.compileOptions, option, 0) < 0:
    addOpt(conf.compileOptions, option)

proc addLinkOptionCmd*(conf: ConfigRef; option: string) =
  addOpt(conf.linkOptionsCmd, option)

proc addCompileOptionCmd*(conf: ConfigRef; option: string) =
  conf.compileOptionsCmd.add(option)

proc initVars*(conf: ConfigRef) =
  # we need to define the symbol here, because ``CC`` may have never been set!
  for c in CC: undefSymbol(conf.symbols, c.name)
  defineSymbol(conf.symbols, CC[conf.cCompiler].name)
  addCompileOption(conf, getConfigVar(conf, conf.cCompiler, ".options.always"))
  #addLinkOption(getConfigVar(cCompiler, ".options.linker"))
  if conf.cCompilerPath.len == 0:
    conf.cCompilerPath = getConfigVar(conf, conf.cCompiler, ".path")

proc completeCfilePath*(conf: ConfigRef; cfile: AbsoluteFile,
                        createSubDir: bool = true): AbsoluteFile =
  result = completeGeneratedFilePath(conf, cfile, createSubDir)

proc toObjFile*(conf: ConfigRef; filename: AbsoluteFile): AbsoluteFile =
  # Object file for compilation
  result = AbsoluteFile(filename.string & "." & CC[conf.cCompiler].objExt)

proc addFileToCompile*(conf: ConfigRef; cf: Cfile) =
  conf.toCompile.add(cf)

proc addLocalCompileOption*(conf: ConfigRef; option: string; nimfile: AbsoluteFile) =
  let key = completeCfilePath(conf, withPackageName(conf, nimfile)).string
  var value = conf.cfileSpecificOptions.getOrDefault(key)
  if strutils.find(value, option, 0) < 0:
    addOpt(value, option)
    conf.cfileSpecificOptions[key] = value

proc resetCompilationLists*(conf: ConfigRef) =
  conf.toCompile.setLen 0
  ## XXX: we must associate these with their originating module
  # when the module is loaded/unloaded it adds/removes its items
  # That's because we still need to hash check the external files
  # Maybe we can do that in checkDep on the other hand?
  conf.externalToLink.setLen 0

proc addExternalFileToLink*(conf: ConfigRef; filename: AbsoluteFile) =
  conf.externalToLink.insert(filename.string, 0)

proc execWithEcho(conf: ConfigRef; cmd: string, msg = hintExecuting): int =
  rawMessage(conf, msg, if msg == hintLinking and not(optListCmd in conf.globalOptions or conf.verbosity > 1): "" else: cmd)
  result = execCmd(cmd)

proc execExternalProgram*(conf: ConfigRef; cmd: string, msg = hintExecuting) =
  if execWithEcho(conf, cmd, msg) != 0:
    rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
      cmd)

proc generateScript(conf: ConfigRef; script: Rope) =
  let (_, name, _) = splitFile(conf.outFile.string)
  let filename = getNimcacheDir(conf) / RelativeFile(addFileExt("compile_" & name,
                                     platform.OS[conf.target.targetOS].scriptExt))
  if not writeRope(script, filename):
    rawMessage(conf, errGenerated, "could not write to file: " & filename.string)

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
  result = conf.globalOptions * {optGenScript, optGenMapping} != {}

proc cFileSpecificOptions(conf: ConfigRef; nimname, fullNimFile: string): string =
  result = conf.compileOptions

  for option in conf.compileOptionsCmd:
    if strutils.find(result, option, 0) < 0:
      addOpt(result, option)

  if optCDebug in conf.globalOptions:
    let key = nimname & ".debug"
    if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))
    else: addOpt(result, getDebug(conf, conf.cCompiler))
  if optOptimizeSpeed in conf.options:
    let key = nimname & ".speed"
    if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))
    else: addOpt(result, getOptSpeed(conf, conf.cCompiler))
  elif optOptimizeSize in conf.options:
    let key = nimname & ".size"
    if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))
    else: addOpt(result, getOptSize(conf, conf.cCompiler))
  let key = nimname & ".always"
  if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))

  addOpt(result, conf.cfileSpecificOptions.getOrDefault(fullNimFile))

proc getCompileOptions(conf: ConfigRef): string =
  result = cFileSpecificOptions(conf, "__dummy__", "__dummy__")

proc vccplatform(conf: ConfigRef): string =
  # VCC specific but preferable over the config hacks people
  # had to do before, see #11306
  if conf.cCompiler == ccVcc:
    let exe = getConfigVar(conf, conf.cCompiler, ".exe")
    if "vccexe.exe" == extractFilename(exe):
      result = case conf.target.targetCPU
        of cpuI386: " --platform:x86"
        of cpuArm: " --platform:arm"
        of cpuAmd64: " --platform:amd64"
        else: ""

proc getLinkOptions(conf: ConfigRef): string =
  result = conf.linkOptions & " " & conf.linkOptionsCmd & " "
  for linkedLib in items(conf.cLinkedLibs):
    result.add(CC[conf.cCompiler].linkLibCmd % linkedLib.quoteShell)
  for libDir in items(conf.cLibs):
    result.add(join([CC[conf.cCompiler].linkDirCmd, libDir.quoteShell]))

proc needsExeExt(conf: ConfigRef): bool {.inline.} =
  result = (optGenScript in conf.globalOptions and conf.target.targetOS == osWindows) or
           (conf.target.hostOS == osWindows)

proc useCpp(conf: ConfigRef; cfile: AbsoluteFile): bool =
  conf.backend == backendCpp and not cfile.string.endsWith(".c")

proc envFlags(conf: ConfigRef): string =
  result = if conf.backend == backendCpp:
            getEnv("CXXFLAGS")
          else:
            getEnv("CFLAGS")

proc getCompilerExe(conf: ConfigRef; compiler: TSystemCC; cfile: AbsoluteFile): string =
  if compiler == ccEnv:
    result = if useCpp(conf, cfile):
              getEnv("CXX")
            else:
              getEnv("CC")
  else:
    result = if useCpp(conf, cfile):
              CC[compiler].cppCompiler
            else:
              CC[compiler].compilerExe
  if result.len == 0:
    rawMessage(conf, errGenerated,
      "Compiler '$1' doesn't support the requested target" %
      CC[compiler].name)

proc ccHasSaneOverflow*(conf: ConfigRef): bool =
  if conf.cCompiler == ccGcc:
    result = false # assume an old or crappy GCC
    var exe = getConfigVar(conf, conf.cCompiler, ".exe")
    if exe.len == 0: exe = CC[conf.cCompiler].compilerExe
    let (s, exitCode) = try: execCmdEx(exe & " --version") except: ("", 1)
    if exitCode == 0:
      var i = 0
      var j = 0
      # the version is the last part of the first line:
      while i < s.len and s[i] != '\n':
        if s[i] in {' ', '\t'}: j = i+1
        inc i
      if j > 0:
        var major = 0
        while j < s.len and s[j] in {'0'..'9'}:
          major = major * 10 + (ord(s[j]) - ord('0'))
          inc j
        if i < s.len and s[j] == '.': inc j
        while j < s.len and s[j] in {'0'..'9'}:
          inc j
        if j+1 < s.len and s[j] == '.' and s[j+1] in {'0'..'9'}:
          # we found a third version number, chances are high
          # we really parsed the version:
          result = major >= 5
  else:
    result = conf.cCompiler == ccCLang

proc getLinkerExe(conf: ConfigRef; compiler: TSystemCC): string =
  result = if CC[compiler].linkerExe.len > 0: CC[compiler].linkerExe
           elif optMixedMode in conf.globalOptions and conf.backend != backendCpp: CC[compiler].cppCompiler
           else: getCompilerExe(conf, compiler, AbsoluteFile"")

proc getCompileCFileCmd*(conf: ConfigRef; cfile: Cfile,
                         isMainFile = false; produceOutput = false): string =
  let c = conf.cCompiler
  # We produce files like module.nim.cpp, so the absolute Nim filename is not
  # cfile.name but `cfile.cname.changeFileExt("")`:
  var options = cFileSpecificOptions(conf, cfile.nimname, cfile.cname.changeFileExt("").string)
  if useCpp(conf, cfile.cname):
    # needs to be prepended so that --passc:-std=c++17 can override default.
    # we could avoid allocation by making cFileSpecificOptions inplace
    options = CC[c].cppXsupport & ' ' & options

  var exe = getConfigVar(conf, c, ".exe")
  if exe.len == 0: exe = getCompilerExe(conf, c, cfile.cname)

  if needsExeExt(conf): exe = addFileExt(exe, "exe")
  if (optGenDynLib in conf.globalOptions or (conf.hcrOn and not isMainFile)) and
      ospNeedsPIC in platform.OS[conf.target.targetOS].props:
    options.add(' ' & CC[c].pic)

  if cfile.customArgs != "":
    options.add ' '
    options.add cfile.customArgs

  var compilePattern: string
  # compute include paths:
  var includeCmd = CC[c].includeCmd & quoteShell(conf.libpath)
  if not noAbsolutePaths(conf):
    for includeDir in items(conf.cIncludes):
      includeCmd.add(join([CC[c].includeCmd, includeDir.quoteShell]))

    compilePattern = joinPath(conf.cCompilerPath, exe)
  else:
    compilePattern = getCompilerExe(conf, c, cfile.cname)

  includeCmd.add(join([CC[c].includeCmd, quoteShell(conf.projectPath.string)]))

  let cf = if noAbsolutePaths(conf): AbsoluteFile extractFilename(cfile.cname.string)
           else: cfile.cname

  let objfile =
    if cfile.obj.isEmpty:
      if CfileFlag.External notin cfile.flags or noAbsolutePaths(conf):
        toObjFile(conf, cf).string
      else:
        completeCfilePath(conf, toObjFile(conf, cf)).string
    elif noAbsolutePaths(conf):
      extractFilename(cfile.obj.string)
    else:
      cfile.obj.string

  # D files are required by nintendo switch libs for
  # compilation. They are basically a list of all includes.
  let dfile = objfile.changeFileExt(".d").quoteShell

  let cfsh = quoteShell(cf)
  result = quoteShell(compilePattern % [
    "dfile", dfile,
    "file", cfsh, "objfile", quoteShell(objfile), "options", options,
    "include", includeCmd, "nim", getPrefixDir(conf).string,
    "lib", conf.libpath.string,
    "ccenvflags", envFlags(conf)])

  if optProduceAsm in conf.globalOptions:
    if CC[conf.cCompiler].produceAsm.len > 0:
      let asmfile = objfile.changeFileExt(".asm").quoteShell
      addOpt(result, CC[conf.cCompiler].produceAsm % ["asmfile", asmfile])
      if produceOutput:
        rawMessage(conf, hintUserRaw, "Produced assembler here: " & asmfile)
    else:
      if produceOutput:
        rawMessage(conf, hintUserRaw, "Couldn't produce assembler listing " &
          "for the selected C compiler: " & CC[conf.cCompiler].name)

  result.add(' ')
  result.addf(CC[c].compileTmpl, [
    "dfile", dfile,
    "file", cfsh, "objfile", quoteShell(objfile),
    "options", options, "include", includeCmd,
    "nim", quoteShell(getPrefixDir(conf)),
    "lib", quoteShell(conf.libpath),
    "vccplatform", vccplatform(conf),
    "ccenvflags", envFlags(conf)])

proc footprint(conf: ConfigRef; cfile: Cfile): SecureHash =
  result = secureHash(
    $secureHashFile(cfile.cname.string) &
    platform.OS[conf.target.targetOS].name &
    platform.CPU[conf.target.targetCPU].name &
    extccomp.CC[conf.cCompiler].name &
    getCompileCFileCmd(conf, cfile))

proc externalFileChanged(conf: ConfigRef; cfile: Cfile): bool =
  if conf.backend == backendJs: return false # pre-existing behavior, but not sure it's good

  let hashFile = toGeneratedFile(conf, conf.withPackageName(cfile.cname), "sha1")
  let currentHash = footprint(conf, cfile)
  var f: File
  if open(f, hashFile.string, fmRead):
    let oldHash = parseSecureHash(f.readLine())
    close(f)
    result = oldHash != currentHash
  else:
    result = true
  if result:
    if open(f, hashFile.string, fmWrite):
      f.writeLine($currentHash)
      close(f)

proc addExternalFileToCompile*(conf: ConfigRef; c: var Cfile) =
  if optForceFullMake notin conf.globalOptions and fileExists(c.obj) and
      not externalFileChanged(conf, c):
    c.flags.incl CfileFlag.Cached
  else:
    # make sure Nim keeps recompiling the external file on reruns
    # if compilation is not successful
    discard tryRemoveFile(c.obj.string)
  conf.toCompile.add(c)

proc addExternalFileToCompile*(conf: ConfigRef; filename: AbsoluteFile) =
  var c = Cfile(nimname: splitFile(filename).name, cname: filename,
    obj: toObjFile(conf, completeCfilePath(conf, filename, false)),
    flags: {CfileFlag.External})
  addExternalFileToCompile(conf, c)

proc getLinkCmd(conf: ConfigRef; output: AbsoluteFile,
                objfiles: string, isDllBuild: bool): string =
  if optGenStaticLib in conf.globalOptions:
    removeFile output # fixes: bug #16947
    result = CC[conf.cCompiler].buildLib % ["libfile", quoteShell(output),
                                            "objfiles", objfiles]
  else:
    var linkerExe = getConfigVar(conf, conf.cCompiler, ".linkerexe")
    if linkerExe.len == 0: linkerExe = getLinkerExe(conf, conf.cCompiler)
    # bug #6452: We must not use ``quoteShell`` here for ``linkerExe``
    if needsExeExt(conf): linkerExe = addFileExt(linkerExe, "exe")
    if noAbsolutePaths(conf): result = linkerExe
    else: result = joinPath(conf.cCompilerPath, linkerExe)
    let buildgui = if optGenGuiApp in conf.globalOptions and conf.target.targetOS == osWindows:
                     CC[conf.cCompiler].buildGui
                   else:
                     ""
    let builddll = if isDllBuild: CC[conf.cCompiler].buildDll else: ""
    let exefile = quoteShell(output)

    when false:
      if optCDebug in conf.globalOptions:
        writeDebugInfo(exefile.changeFileExt("ndb"))

    # Map files are required by Nintendo Switch compilation. They are a list
    # of all function calls in the library and where they come from.
    let mapfile = quoteShell(getNimcacheDir(conf) / RelativeFile(splitFile(output).name & ".map"))

    let linkOptions = getLinkOptions(conf) & " " &
                      getConfigVar(conf, conf.cCompiler, ".options.linker")
    var linkTmpl = getConfigVar(conf, conf.cCompiler, ".linkTmpl")
    if linkTmpl.len == 0:
      linkTmpl = CC[conf.cCompiler].linkTmpl
    result = quoteShell(result % ["builddll", builddll,
        "mapfile", mapfile,
        "buildgui", buildgui, "options", linkOptions, "objfiles", objfiles,
        "exefile", exefile, "nim", getPrefixDir(conf).string, "lib", conf.libpath.string])
    result.add ' '
    result.addf(linkTmpl, ["builddll", builddll,
        "mapfile", mapfile,
        "buildgui", buildgui, "options", linkOptions,
        "objfiles", objfiles, "exefile", exefile,
        "nim", quoteShell(getPrefixDir(conf)),
        "lib", quoteShell(conf.libpath),
        "vccplatform", vccplatform(conf)])
    # On windows the debug information for binaries is emitted in a separate .pdb
    # file and the binaries (.dll and .exe) contain a full path to that .pdb file.
    # This is a problem for hot code reloading because even when we copy the .dll
    # and load the copy so the build process may overwrite the original .dll on
    # the disk (windows locks the files of running binaries) the copy still points
    # to the original .pdb (and a simple copy of the .pdb won't help). This is a
    # problem when a debugger is attached to the program we are hot-reloading.
    # This problem is nonexistent on Unix since there by default debug symbols
    # are embedded in the binaries so loading a copy of a .so will be fine. There
    # is the '/Z7' flag for the MSVC compiler to embed the debug info of source
    # files into their respective .obj files but the linker still produces a .pdb
    # when a final .dll or .exe is linked so the debug info isn't embedded.
    # There is also the issue that even when a .dll is unloaded the debugger
    # still keeps the .pdb for that .dll locked. This is a major problem and
    # because of this we cannot just alternate between 2 names for a .pdb file
    # when rebuilding a .dll - instead we need to accumulate differently named
    # .pdb files in the nimcache folder - this is the easiest and most reliable
    # way of being able to debug and rebuild the program at the same time. This
    # is accomplished using the /PDB:<filename> flag (there also exists the
    # /PDBALTPATH:<filename> flag). The only downside is that the .pdb files are
    # at least 300kb big (when linking statically to the runtime - or else 5mb+)
    # and will quickly accumulate. There is a hacky solution: we could try to
    # delete all .pdb files with a pattern and swallow exceptions.
    #
    # links about .pdb files and hot code reloading:
    # https://ourmachinery.com/post/dll-hot-reloading-in-theory-and-practice/
    # https://ourmachinery.com/post/little-machines-working-together-part-2/
    # https://github.com/fungos/cr
    # https://fungos.github.io/blog/2017/11/20/cr.h-a-simple-c-hot-reload-header-only-library/
    # on forcing the debugger to unlock a locked .pdb of an unloaded library:
    # https://blog.molecular-matters.com/2017/05/09/deleting-pdb-files-locked-by-visual-studio/
    # and a bit about the .pdb format in case that is ever needed:
    # https://github.com/crosire/blink
    # http://www.debuginfo.com/articles/debuginfomatch.html#pdbfiles
    if conf.hcrOn and isVSCompatible(conf):
      let t = now()
      let pdb = output.string & "." & format(t, "MMMM-yyyy-HH-mm-") & $t.nanosecond & ".pdb"
      result.add " /link /PDB:" & pdb
  if optCDebug in conf.globalOptions and conf.cCompiler == ccVcc:
    result.add " /Zi /FS /Od"

template getLinkCmd(conf: ConfigRef; output: AbsoluteFile, objfiles: string): string =
  getLinkCmd(conf, output, objfiles, optGenDynLib in conf.globalOptions)

template tryExceptOSErrorMessage(conf: ConfigRef; errorPrefix: string = "", body: untyped) =
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

proc getExtraCmds(conf: ConfigRef; output: AbsoluteFile): seq[string] =
  when defined(macosx):
    if optCDebug in conf.globalOptions and optGenStaticLib notin conf.globalOptions:
      # if needed, add an option to skip or override location
      result.add "dsymutil " & $(output).quoteShell

proc execLinkCmd(conf: ConfigRef; linkCmd: string) =
  tryExceptOSErrorMessage(conf, "invocation of external linker program failed."):
    execExternalProgram(conf, linkCmd, hintLinking)

proc execCmdsInParallel(conf: ConfigRef; cmds: seq[string]; prettyCb: proc (idx: int)) =
  let runCb = proc (idx: int, p: Process) =
    let exitCode = p.peekExitCode
    if exitCode != 0:
      rawMessage(conf, errGenerated, "execution of an external compiler program '" &
        cmds[idx] & "' failed with exit code: " & $exitCode & "\n\n")
  if conf.numberOfProcessors == 0: conf.numberOfProcessors = countProcessors()
  var res = 0
  if conf.numberOfProcessors <= 1:
    for i in 0..high(cmds):
      tryExceptOSErrorMessage(conf, "invocation of external compiler program failed."):
        res = execWithEcho(conf, cmds[i])
      if res != 0:
        rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
          cmds[i])
  else:
    tryExceptOSErrorMessage(conf, "invocation of external compiler program failed."):
      res = execProcesses(cmds, {poStdErrToStdOut, poUsePath, poParentStreams},
                            conf.numberOfProcessors, prettyCb, afterRunEvent=runCb)
  if res != 0:
    if conf.numberOfProcessors <= 1:
      rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
        cmds.join())

proc linkViaResponseFile(conf: ConfigRef; cmd: string) =
  # Extracting the linker.exe here is a bit hacky but the best solution
  # given ``buildLib``'s design.
  var i = 0
  var last = 0
  if cmd.len > 0 and cmd[0] == '"':
    inc i
    while i < cmd.len and cmd[i] != '"': inc i
    last = i
    inc i
  else:
    while i < cmd.len and cmd[i] != ' ': inc i
    last = i
  while i < cmd.len and cmd[i] == ' ': inc i
  let linkerArgs = conf.projectName & "_" & "linkerArgs.txt"
  let args = cmd.substr(i)
  # GCC's response files don't support backslashes. Junk.
  if conf.cCompiler == ccGcc or conf.cCompiler == ccCLang:
    writeFile(linkerArgs, args.replace('\\', '/'))
  else:
    writeFile(linkerArgs, args)
  try:
    execLinkCmd(conf, cmd.substr(0, last) & " @" & linkerArgs)
  finally:
    removeFile(linkerArgs)

proc getObjFilePath(conf: ConfigRef, f: Cfile): string =
  if noAbsolutePaths(conf): f.obj.extractFilename
  else: f.obj.string

proc hcrLinkTargetName(conf: ConfigRef, objFile: string, isMain = false): AbsoluteFile =
  let basename = splitFile(objFile).name
  let targetName = if isMain: basename & ".exe"
                   else: platform.OS[conf.target.targetOS].dllFrmt % basename
  result = conf.getNimcacheDir / RelativeFile(targetName)

proc displayProgressCC(conf: ConfigRef, path, compileCmd: string): string =
  if conf.hasHint(hintCC):
    if optListCmd in conf.globalOptions or conf.verbosity > 1:
      result = MsgKindToStr[hintCC] % (demanglePackageName(path.splitFile.name) & ": " & compileCmd)
    else:
      result = MsgKindToStr[hintCC] % demanglePackageName(path.splitFile.name)

proc callCCompiler*(conf: ConfigRef) =
  var
    linkCmd: string
    extraCmds: seq[string]
  if conf.globalOptions * {optCompileOnly, optGenScript} == {optCompileOnly}:
    return # speed up that call if only compiling and no script shall be
           # generated
  #var c = cCompiler
  var script: Rope = nil
  var cmds: TStringSeq
  var prettyCmds: TStringSeq
  let prettyCb = proc (idx: int) =
    if prettyCmds[idx].len > 0:
      flushDot(conf)
      # xxx should probably use stderr like other compiler messages, not stdout
      echo prettyCmds[idx]

  for idx, it in conf.toCompile:
    # call the C compiler for the .c file:
    if CfileFlag.Cached in it.flags: continue
    let compileCmd = getCompileCFileCmd(conf, it, idx == conf.toCompile.len - 1, produceOutput=true)
    if optCompileOnly notin conf.globalOptions:
      cmds.add(compileCmd)
      prettyCmds.add displayProgressCC(conf, $it.cname, compileCmd)
    if optGenScript in conf.globalOptions:
      script.add(compileCmd)
      script.add("\n")

  if optCompileOnly notin conf.globalOptions:
    execCmdsInParallel(conf, cmds, prettyCb)
  if optNoLinking notin conf.globalOptions:
    # call the linker:
    var objfiles = ""
    for it in conf.externalToLink:
      let objFile = if noAbsolutePaths(conf): it.extractFilename else: it
      objfiles.add(' ')
      objfiles.add(quoteShell(
          addFileExt(objFile, CC[conf.cCompiler].objExt)))

    if conf.hcrOn: # lets assume that optCompileOnly isn't on
      cmds = @[]
      let mainFileIdx = conf.toCompile.len - 1
      for idx, x in conf.toCompile:
        # don't relink each of the many binaries (one for each source file) if the nim code is
        # cached because that would take too much time for small changes - the only downside to
        # this is that if an external-to-link file changes the final target wouldn't be relinked
        if CfileFlag.Cached in x.flags: continue
        # we pass each object file as if it is the project file - a .dll will be created for each such
        # object file in the nimcache directory, and only in the case of the main project file will
        # there be probably an executable (if the project is such) which will be copied out of the nimcache
        let objFile = conf.getObjFilePath(x)
        let buildDll = idx != mainFileIdx
        let linkTarget = conf.hcrLinkTargetName(objFile, not buildDll)
        cmds.add(getLinkCmd(conf, linkTarget, objfiles & " " & quoteShell(objFile), buildDll))
        # try to remove all .pdb files for the current binary so they don't accumulate endlessly in the nimcache
        # for more info check the comment inside of getLinkCmd() where the /PDB:<filename> MSVC flag is used
        if isVSCompatible(conf):
          for pdb in walkFiles(objFile & ".*.pdb"):
            discard tryRemoveFile(pdb)
      # execute link commands in parallel - output will be a bit different
      # if it fails than that from execLinkCmd() but that doesn't matter
      prettyCmds = map(prettyCmds, proc (curr: string): string = return curr.replace("CC", "Link"))
      execCmdsInParallel(conf, cmds, prettyCb)
      # only if not cached - copy the resulting main file from the nimcache folder to its originally intended destination
      if CfileFlag.Cached notin conf.toCompile[mainFileIdx].flags:
        let mainObjFile = getObjFilePath(conf, conf.toCompile[mainFileIdx])
        let src = conf.hcrLinkTargetName(mainObjFile, true)
        let dst = conf.prepareToWriteOutput
        copyFileWithPermissions(src.string, dst.string)
    else:
      for x in conf.toCompile:
        let objFile = if noAbsolutePaths(conf): x.obj.extractFilename else: x.obj.string
        objfiles.add(' ')
        objfiles.add(quoteShell(objFile))
      let mainOutput = if optGenScript notin conf.globalOptions: conf.prepareToWriteOutput
                       else: AbsoluteFile(conf.projectName)
      linkCmd = getLinkCmd(conf, mainOutput, objfiles)
      extraCmds = getExtraCmds(conf, mainOutput)
      if optCompileOnly notin conf.globalOptions:
        const MaxCmdLen = when defined(windows): 8_000 else: 32_000
        if linkCmd.len > MaxCmdLen:
          # Windows's command line limit is about 8K (don't laugh...) so C compilers on
          # Windows support a feature where the command line can be passed via ``@linkcmd``
          # to them.
          linkViaResponseFile(conf, linkCmd)
        else:
          execLinkCmd(conf, linkCmd)
        for cmd in extraCmds:
          execExternalProgram(conf, cmd, hintExecuting)
  else:
    linkCmd = ""
  if optGenScript in conf.globalOptions:
    script.add(linkCmd)
    script.add("\n")
    generateScript(conf, script)


template hashNimExe(): string = $secureHashFile(os.getAppFilename())

proc writeJsonBuildInstructions*(conf: ConfigRef) =
  template lit(x: string) = f.write x
  template str(x: string) =
    buf.setLen 0
    escapeJson(x, buf)
    f.write buf

  proc cfiles(conf: ConfigRef; f: File; buf: var string; clist: CfileList, isExternal: bool) =
    var comma = false
    for i, it in clist:
      if CfileFlag.Cached in it.flags: continue
      let compileCmd = getCompileCFileCmd(conf, it)
      if comma: lit ",\L" else: comma = true
      lit "["
      str it.cname.string
      lit ", "
      str compileCmd
      lit "]"

  proc linkfiles(conf: ConfigRef; f: File; buf, objfiles: var string; clist: CfileList;
                 llist: seq[string]) =
    var pastStart = false
    for it in llist:
      let objfile = if noAbsolutePaths(conf): it.extractFilename
                    else: it
      let objstr = addFileExt(objfile, CC[conf.cCompiler].objExt)
      objfiles.add(' ')
      objfiles.add(objstr)
      if pastStart: lit ",\L"
      str objstr
      pastStart = true

    for it in clist:
      let objstr = quoteShell(it.obj)
      objfiles.add(' ')
      objfiles.add(objstr)
      if pastStart: lit ",\L"
      str objstr
      pastStart = true
    lit "\L"

  proc depfiles(conf: ConfigRef; f: File; buf: var string) =
    var i = 0
    for it in conf.m.fileInfos:
      let path = it.fullPath.string
      if isAbsolute(path): # TODO: else?
        if i > 0: lit "],\L"
        lit "["
        str path
        lit ", "
        str $secureHashFile(path)
        inc i
    lit "]\L"


  var buf = newStringOfCap(50)

  let jsonFile = conf.getNimcacheDir / RelativeFile(conf.projectName & ".json")
  conf.jsonBuildFile = jsonFile
  let output = conf.absOutFile

  var f: File
  if open(f, jsonFile.string, fmWrite):
    lit "{\L"
    lit "\"outputFile\": "
    str $output

    lit ",\L\"compile\":[\L"
    cfiles(conf, f, buf, conf.toCompile, false)
    lit "],\L\"link\":[\L"
    var objfiles = ""
    # XXX add every file here that is to link
    linkfiles(conf, f, buf, objfiles, conf.toCompile, conf.externalToLink)

    lit "],\L\"linkcmd\": "
    str getLinkCmd(conf, output, objfiles)

    lit ",\L\"extraCmds\": "
    lit $(%* getExtraCmds(conf, conf.absOutFile))

    lit ",\L\"stdinInput\": "
    lit $(%* conf.projectIsStdin)
    lit ",\L\"projectIsCmd\": "
    lit $(%* conf.projectIsCmd)
    lit ",\L\"cmdInput\": "
    lit $(%* conf.cmdInput)
    lit ",\L\"currentDir\": "
    lit $(%* getCurrentDir())

    if optRun in conf.globalOptions or isDefined(conf, "nimBetterRun"):
      lit ",\L\"cmdline\": "
      str conf.commandLine
      lit ",\L\"depfiles\":[\L"
      depfiles(conf, f, buf)
      lit "],\L\"nimexe\": \L"
      str hashNimExe()
      lit "\L"

    lit "\L}\L"
    close(f)

proc changeDetectedViaJsonBuildInstructions*(conf: ConfigRef; projectfile: AbsoluteFile): bool =
  let jsonFile = toGeneratedFile(conf, projectfile, "json")
  if not fileExists(jsonFile): return true
  if not fileExists(conf.absOutFile): return true
  result = false
  try:
    let data = json.parseFile(jsonFile.string)
    for key in "depfiles cmdline stdinInput currentDir".split:
      if not data.hasKey(key): return true
    if getCurrentDir() != data["currentDir"].getStr:
      # fixes bug #16271
      # Note that simply comparing `expandFilename(projectFile)` would
      # not be sufficient in case other flags depend implicitly on `getCurrentDir`,
      # and would require much more care. Simply re-compiling is safer for now.
      # A better strategy for future work would be to cache (with an LRU cache)
      # the N most recent unique build instructions, as done with `rdmd`,
      # which is both robust and avoids recompilation when switching back and forth
      # between projects, see https://github.com/timotheecour/Nim/issues/199
      return true
    let oldCmdLine = data["cmdline"].getStr
    if conf.commandLine != oldCmdLine:
      return true
    if hashNimExe() != data["nimexe"].getStr:
      return true
    let stdinInput = data["stdinInput"].getBool
    let projectIsCmd = data["projectIsCmd"].getBool
    if conf.projectIsStdin or stdinInput:
      # could optimize by returning false if stdin input was the same,
      # but I'm not sure how to get full stding input
      return true

    if conf.projectIsCmd or projectIsCmd:
      if not (conf.projectIsCmd and projectIsCmd): return true
      if not data.hasKey("cmdInput"): return true
      let cmdInput = data["cmdInput"].getStr
      if cmdInput != conf.cmdInput: return true

    let depfilesPairs = data["depfiles"]
    doAssert depfilesPairs.kind == JArray
    for p in depfilesPairs:
      doAssert p.kind == JArray
      # >= 2 for forwards compatibility with potential later .json files:
      doAssert p.len >= 2
      let depFilename = p[0].getStr
      let oldHashValue = p[1].getStr
      let newHashValue = $secureHashFile(depFilename)
      if oldHashValue != newHashValue:
        return true
  except IOError, OSError, ValueError:
    echo "Warning: JSON processing failed: ", getCurrentExceptionMsg()
    result = true

proc runJsonBuildInstructions*(conf: ConfigRef; projectfile: AbsoluteFile) =
  let jsonFile = toGeneratedFile(conf, projectfile, "json")
  try:
    let data = json.parseFile(jsonFile.string)

    let output = data["outputFile"].getStr
    createDir output.parentDir
    let outputCurrent = $conf.absOutFile
    if output != outputCurrent:
      # previously, any specified output file would be silently ignored;
      # simply copying won't work in some cases, for example with `extraCmds`,
      # so we just make it an error, user should use same command for jsonscript
      # as was used with --compileOnly.
      globalError(conf, gCmdLineInfo, "jsonscript command outputFile '$1' must match '$2' which was specified during --compileOnly, see \"outputFile\" entry in '$3' " % [outputCurrent, output, jsonFile.string])

    let toCompile = data["compile"]
    doAssert toCompile.kind == JArray
    var cmds: TStringSeq
    var prettyCmds: TStringSeq
    let prettyCb = proc (idx: int) =
      if prettyCmds[idx].len > 0: echo prettyCmds[idx]

    for c in toCompile:
      doAssert c.kind == JArray
      doAssert c.len >= 2

      cmds.add(c[1].getStr)
      prettyCmds.add displayProgressCC(conf, c[0].getStr, c[1].getStr)

    execCmdsInParallel(conf, cmds, prettyCb)

    let linkCmd = data["linkcmd"]
    doAssert linkCmd.kind == JString
    execLinkCmd(conf, linkCmd.getStr)
    if data.hasKey("extraCmds"):
      let extraCmds = data["extraCmds"]
      doAssert extraCmds.kind == JArray
      for cmd in extraCmds:
        doAssert cmd.kind == JString, $cmd.kind
        let cmd2 = cmd.getStr
        execExternalProgram(conf, cmd2, hintExecuting)

  except:
    let e = getCurrentException()
    quit "\ncaught exception:\n" & e.msg & "\nstacktrace:\n" & e.getStackTrace() &
         "error evaluating JSON file: " & jsonFile.string

proc genMappingFiles(conf: ConfigRef; list: CfileList): Rope =
  for it in list:
    result.addf("--file:r\"$1\"$N", [rope(it.cname.string)])

proc writeMapping*(conf: ConfigRef; symbolMapping: Rope) =
  if optGenMapping notin conf.globalOptions: return
  var code = rope("[C_Files]\n")
  code.add(genMappingFiles(conf, conf.toCompile))
  code.add("\n[C_Compiler]\nFlags=")
  code.add(strutils.escape(getCompileOptions(conf)))

  code.add("\n[Linker]\nFlags=")
  code.add(strutils.escape(getLinkOptions(conf) & " " &
                            getConfigVar(conf, conf.cCompiler, ".options.linker")))

  code.add("\n[Environment]\nlibpath=")
  code.add(strutils.escape(conf.libpath.string))

  code.addf("\n[Symbols]$n$1", [symbolMapping])
  let filename = conf.projectPath / RelativeFile"mapping.txt"
  if not writeRope(code, filename):
    rawMessage(conf, errGenerated, "could not write to file: " & filename.string)
