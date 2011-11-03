#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
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
    ccTcc, ccPcc, ccUcc, ccIcc, ccGpp
  TInfoCCProp* = enum         # properties of the C compiler:
    hasSwitchRange,           # CC allows ranges in switch statements (GNU C)
    hasComputedGoto,          # CC has computed goto (GNU C extension)
    hasCpp,                   # CC is/contains a C++ compiler
    hasAssume                 # CC has __assume (Visual C extension)
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
    linkerExe: string,   # the linker's executable
    linkTmpl: string,    # command to link files to produce an exe
    includeCmd: string,  # command to add an include dir
    debug: string,       # flags for debug build
    pic: string,         # command for position independent code
                         # used on some platforms
    asmStmtFrmt: string, # format of ASM statement
    props: TInfoCCProps] # properties of the C compiler

const 
  CC*: array[succ(low(TSystemCC))..high(TSystemCC), TInfoCC] = [
    (name: "gcc", 
     objExt: "o", 
     optSpeed: " -O3 -ffast-math ", 
     optSize: " -Os -ffast-math ", 
     compilerExe: "gcc", 
     compileTmpl: "-c $options $include -o $objfile $file", 
     buildGui: " -mwindows", 
     buildDll: " -shared", 
     linkerExe: "gcc", 
     linkTmpl: "$buildgui $builddll -o $exefile $objfiles $options", 
     includeCmd: " -I", 
     debug: "", 
     pic: "-fPIC", 
     asmStmtFrmt: "asm($1);$n", 
     props: {hasSwitchRange, hasComputedGoto, hasCpp}), 
    (name: "llvm_gcc", 
     objExt: "o", 
     optSpeed: " -O3 -ffast-math ", 
     optSize: " -Os -ffast-math ", 
     compilerExe: "llvm-gcc", 
     compileTmpl: "-c $options $include -o $objfile $file", 
     buildGui: " -mwindows", 
     buildDll: " -shared", 
     linkerExe: "llvm-gcc", 
     linkTmpl: "$buildgui $builddll -o $exefile $objfiles $options", 
     includeCmd: " -I", 
     debug: "", 
     pic: "-fPIC", 
     asmStmtFrmt: "asm($1);$n", 
     props: {hasSwitchRange, hasComputedGoto, hasCpp}), 
    (name: "clang", 
     objExt: "o", 
     optSpeed: " -O3 -ffast-math ", 
     optSize: " -Os -ffast-math ", 
     compilerExe: "clang", 
     compileTmpl: "-c $options $include -o $objfile $file", 
     buildGui: " -mwindows", 
     buildDll: " -shared", 
     linkerExe: "clang", 
     linkTmpl: "$buildgui $builddll -o $exefile $objfiles $options", 
     includeCmd: " -I", 
     debug: "", 
     pic: "-fPIC", 
     asmStmtFrmt: "asm($1);$n", 
     props: {hasSwitchRange, hasComputedGoto, hasCpp}), 
    (name: "lcc", 
     objExt: "obj", 
     optSpeed: " -O -p6 ", 
     optSize: " -O -p6 ", 
     compilerExe: "lcc", 
     compileTmpl: "$options $include -Fo$objfile $file", 
     buildGui: " -subsystem windows", 
     buildDll: " -dll", 
     linkerExe: "lcclnk", 
     linkTmpl: "$options $buildgui $builddll -O $exefile $objfiles", 
     includeCmd: " -I", 
     debug: " -g5 ", 
     pic: "", 
     asmStmtFrmt: "_asm{$n$1$n}$n", 
     props: {}), 
    (name: "bcc", 
     objExt: "obj", 
     optSpeed: " -O2 -6 ", 
     optSize: " -O1 -6 ", 
     compilerExe: "bcc32", 
     compileTmpl: "-c $options $include -o$objfile $file", 
     buildGui: " -tW", 
     buildDll: " -tWD", 
     linkerExe: "bcc32", 
     linkTmpl: "$options $buildgui $builddll -e$exefile $objfiles", 
     includeCmd: " -I", 
     debug: "", 
     pic: "", 
     asmStmtFrmt: "__asm{$n$1$n}$n", 
     props: {hasCpp}), 
    (name: "dmc", 
     objExt: "obj", 
     optSpeed: " -ff -o -6 ", 
     optSize: " -ff -o -6 ", 
     compilerExe: "dmc", 
     compileTmpl: "-c $options $include -o$objfile $file", 
     buildGui: " -L/exet:nt/su:windows", 
     buildDll: " -WD", 
     linkerExe: "dmc", 
     linkTmpl: "$options $buildgui $builddll -o$exefile $objfiles", 
     includeCmd: " -I", 
     debug: " -g ", 
     pic: "", 
     asmStmtFrmt: "__asm{$n$1$n}$n", 
     props: {hasCpp}), 
    (name: "wcc", 
     objExt: "obj", 
     optSpeed: " -ox -on -6 -d0 -fp6 -zW ", 
     optSize: "", 
     compilerExe: "wcl386", 
     compileTmpl: "-c $options $include -fo=$objfile $file", 
     buildGui: " -bw", 
     buildDll: " -bd", 
     linkerExe: "wcl386", 
     linkTmpl: "$options $buildgui $builddll -fe=$exefile $objfiles ", 
     includeCmd: " -i=", 
     debug: " -d2 ", 
     pic: "", 
     asmStmtFrmt: "__asm{$n$1$n}$n", 
     props: {hasCpp}), 
    (name: "vcc", 
     objExt: "obj", 
     optSpeed: " /Ogityb2 /G7 /arch:SSE2 ", 
     optSize: " /O1 /G7 ", 
     compilerExe: "cl", 
     compileTmpl: "/c $options $include /Fo$objfile $file", 
     buildGui: " /link /SUBSYSTEM:WINDOWS ", 
     buildDll: " /LD", 
     linkerExe: "cl", 
     linkTmpl: "$options $builddll /Fe$exefile $objfiles $buildgui", 
     includeCmd: " /I", 
     debug: " /GZ /Zi ", 
     pic: "", 
     asmStmtFrmt: "__asm{$n$1$n}$n", 
     props: {hasCpp, hasAssume}), 
    (name: "tcc", 
     objExt: "o", 
     optSpeed: "", 
     optSize: "", 
     compilerExe: "tcc", 
     compileTmpl: "-c $options $include -o $objfile $file", 
     buildGui: "UNAVAILABLE!", 
     buildDll: " -shared", 
     linkerExe: "tcc", 
     linkTmpl: "-o $exefile $options $buildgui $builddll $objfiles", 
     includeCmd: " -I", 
     debug: " -g ", 
     pic: "", 
     asmStmtFrmt: "__asm{$n$1$n}$n", 
     props: {hasSwitchRange, hasComputedGoto}), 
    (name: "pcc", # Pelles C
     objExt: "obj", 
     optSpeed: " -Ox ", 
     optSize: " -Os ", 
     compilerExe: "cc", 
     compileTmpl: "-c $options $include -Fo$objfile $file", 
     buildGui: " -SUBSYSTEM:WINDOWS", 
     buildDll: " -DLL", 
     linkerExe: "cc", 
     linkTmpl: "$options $buildgui $builddll -OUT:$exefile $objfiles", 
     includeCmd: " -I", 
     debug: " -Zi ", 
     pic: "", 
     asmStmtFrmt: "__asm{$n$1$n}$n", 
     props: {}), 
    (name: "ucc", 
     objExt: "o", 
     optSpeed: " -O3 ", 
     optSize: " -O1 ", 
     compilerExe: "cc", 
     compileTmpl: "-c $options $include -o $objfile $file", 
     buildGui: "", 
     buildDll: " -shared ", 
     linkerExe: "cc", 
     linkTmpl: "-o $exefile $buildgui $builddll $objfiles $options", 
     includeCmd: " -I", 
     debug: "", 
     pic: "", 
     asmStmtFrmt: "__asm{$n$1$n}$n", 
     props: {}), 
    (name: "icc", 
     objExt: "o", 
     optSpeed: " -O3 ", 
     optSize: " -Os ", 
     compilerExe: "icc", 
     compileTmpl: "-c $options $include -o $objfile $file", 
     buildGui: " -mwindows", 
     buildDll: " -mdll", 
     linkerExe: "icc", 
     linkTmpl: "$options $buildgui $builddll -o $exefile $objfiles", 
     includeCmd: " -I", 
     debug: "", 
     pic: "-fPIC", 
     asmStmtFrmt: "asm($1);$n", 
     props: {hasSwitchRange, hasComputedGoto, hasCpp}), 
    (name: "gpp", 
     objExt: "o", 
     optSpeed: " -O3 -ffast-math ", 
     optSize: " -Os -ffast-math ", 
     compilerExe: "g++", 
     compileTmpl: "-c $options $include -o $objfile $file", 
     buildGui: " -mwindows", 
     buildDll: " -mdll", 
     linkerExe: "g++", 
     linkTmpl: "$buildgui $builddll -o $exefile $objfiles $options", 
     includeCmd: " -I", 
     debug: " -g ", 
     pic: "-fPIC", 
     asmStmtFrmt: "asm($1);$n", 
     props: {hasSwitchRange, hasComputedGoto, hasCpp})]

var ccompiler*: TSystemCC = ccGcc # the used compiler

const               
  hExt* = "h"

var cExt*: string = "c" # extension of generated C/C++ files
                        # (can be changed to .cpp later)

# implementation

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

proc setCC*(ccname: string) = 
  ccompiler = nameToCC(ccname)
  if ccompiler == ccNone: rawMessage(errUnknownCcompiler, ccname)
  compileOptions = getConfigVar(CC[ccompiler].name & ".options.always")
  linkOptions = getConfigVar(CC[ccompiler].name & ".options.linker")
  ccompilerpath = getConfigVar(CC[ccompiler].name & ".path")
  for i in countup(low(CC), high(CC)): undefSymbol(CC[i].name)
  defineSymbol(CC[ccompiler].name)

proc addOpt(dest: var string, src: string) = 
  if len(dest) == 0 or dest[len(dest) - 1 + 0] != ' ': add(dest, " ")
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
  addCompileOption(getConfigVar(CC[ccompiler].name & ".options.always"))
  addLinkOption(getConfigVar(CC[ccompiler].name & ".options.linker"))
  if len(ccompilerPath) == 0: 
    ccompilerpath = getConfigVar(CC[ccompiler].name & ".path")

proc completeCFilePath*(cfile: string, createSubDir: bool = true): string = 
  result = completeGeneratedFilePath(cfile, createSubDir)

proc toObjFile*(filenameWithoutExt: string): string = 
  # Object file for compilation
  result = changeFileExt(filenameWithoutExt, cc[ccompiler].objExt)

proc addFileToCompile*(filename: string) = 
  appendStr(toCompile, filename)

proc footprint(filename: string): TCrc32 =
  result = crcFromFile(filename) >< 
      platform.OS[targetOS].name ><
      platform.CPU[targetCPU].name ><
      extccomp.CC[extccomp.ccompiler].name

proc externalFileChanged(filename: string): bool = 
  var crcFile = toGeneratedFile(filename, "crc")
  var currentCrc = int(footprint(filename))
  var f: TFile
  if open(f, crcFile, fmRead): 
    var line = f.readLine()
    if isNil(line) or line.len == 0: line = "0"
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

proc addFileToLink*(filename: string) = 
  prependStr(toLink, filename) 
  # BUGFIX: was ``appendStr``

proc execExternalProgram*(cmd: string) = 
  if optListCmd in gGlobalOptions or gVerbosity > 0: MsgWriteln(cmd)
  if execCmd(cmd) != 0: rawMessage(errExecutionOfProgramFailed, "")

proc generateScript(projectFile: string, script: PRope) = 
  var (dir, name, ext) = splitFile(projectFile)
  WriteRope(script, dir / addFileExt("compile_" & name, 
                                     platform.os[targetOS].scriptExt))

proc getOptSpeed(c: TSystemCC): string = 
  result = getConfigVar(cc[c].name & ".options.speed")
  if result == "": 
    result = cc[c].optSpeed   # use default settings from this file

proc getDebug(c: TSystemCC): string = 
  result = getConfigVar(cc[c].name & ".options.debug")
  if result == "": 
    result = cc[c].debug      # use default settings from this file

proc getOptSize(c: TSystemCC): string = 
  result = getConfigVar(cc[c].name & ".options.size")
  if result == "": 
    result = cc[c].optSize    # use default settings from this file

const 
  specialFileA = 42
  specialFileB = 42

var fileCounter: int

proc getCompileCFileCmd*(cfilename: string, isExternal: bool = false): string = 
  var 
    cfile, objfile, options, includeCmd, compilePattern, key, trunk, exe: string
  var c = ccompiler
  options = compileOptions
  trunk = splitFile(cfilename).name
  if optCDebug in gGlobalOptions: 
    key = trunk & ".debug"
    if existsConfigVar(key): addOpt(options, getConfigVar(key))
    else: addOpt(options, getDebug(c))
  if (optOptimizeSpeed in gOptions): 
    #if ((fileCounter >= specialFileA) and (fileCounter <= specialFileB)) then
    key = trunk & ".speed"
    if existsConfigVar(key): addOpt(options, getConfigVar(key))
    else: addOpt(options, getOptSpeed(c))
  elif optOptimizeSize in gOptions: 
    key = trunk & ".size"
    if existsConfigVar(key): addOpt(options, getConfigVar(key))
    else: addOpt(options, getOptSize(c))
  key = trunk & ".always"
  if existsConfigVar(key): addOpt(options, getConfigVar(key))
  exe = cc[c].compilerExe
  key = cc[c].name & ".exe"
  if existsConfigVar(key): exe = getConfigVar(key)
  if targetOS == osWindows: exe = addFileExt(exe, "exe")
  if optGenDynLib in gGlobalOptions and
      ospNeedsPIC in platform.OS[targetOS].props: 
    add(options, ' ' & cc[c].pic)
  if targetOS == platform.hostOS: 
    # compute include paths:
    includeCmd = cc[c].includeCmd # this is more complex than needed, but
                                  # a workaround of a FPC bug...
    add(includeCmd, quoteIfContainsWhite(libpath))
    compilePattern = JoinPath(ccompilerpath, exe)
  else: 
    includeCmd = ""
    compilePattern = cc[c].compilerExe
  if targetOS == platform.hostOS: cfile = cfilename
  else: cfile = extractFileName(cfilename)
  if not isExternal or targetOS != platform.hostOS: objfile = toObjFile(cfile)
  else: objfile = completeCFilePath(toObjFile(cfile))
  cfile = quoteIfContainsWhite(AddFileExt(cfile, cExt))
  objfile = quoteIfContainsWhite(objfile)
  result = quoteIfContainsWhite(`%`(compilePattern, ["file", cfile, "objfile", 
      objfile, "options", options, "include", includeCmd, "nimrod", 
      getPrefixDir(), "lib", libpath]))
  add(result, ' ')
  addf(result, cc[c].compileTmpl, [
    "file", cfile, "objfile", objfile, 
    "options", options, "include", includeCmd, 
    "nimrod", quoteIfContainsWhite(getPrefixDir()), 
    "lib", quoteIfContainsWhite(libpath)])

proc CompileCFile(list: TLinkedList, script: var PRope, cmds: var TStringSeq, 
                  isExternal: bool) = 
  var it = PStrEntry(list.head)
  while it != nil: 
    inc(fileCounter)          # call the C compiler for the .c file:
    var compileCmd = getCompileCFileCmd(it.data, isExternal)
    if not (optCompileOnly in gGlobalOptions): 
      add(cmds, compileCmd)
    if (optGenScript in gGlobalOptions): 
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
    elif (optListCmd in gGlobalOptions) or (gVerbosity > 0): 
      res = execProcesses(cmds, {poEchoCmd, poUseShell, poParentStreams}, 
                          gNumberOfProcessors)
    else: 
      res = execProcesses(cmds, {poUseShell, poParentStreams}, 
                          gNumberOfProcessors)
    if res != 0: rawMessage(errExecutionOfProgramFailed, [])
  if optNoLinking notin gGlobalOptions: 
    # call the linker:
    var linkerExe = getConfigVar(cc[c].name & ".linkerexe")
    if len(linkerExe) == 0: linkerExe = cc[c].linkerExe
    if targetOS == osWindows: linkerExe = addFileExt(linkerExe, "exe")
    if (platform.hostOS != targetOS): linkCmd = quoteIfContainsWhite(linkerExe)
    else: linkCmd = quoteIfContainsWhite(JoinPath(ccompilerpath, linkerExe))
    if optGenGuiApp in gGlobalOptions: buildGui = cc[c].buildGui
    else: buildGui = ""
    var exefile: string
    if optGenDynLib in gGlobalOptions: 
      exefile = `%`(platform.os[targetOS].dllFrmt, [splitFile(projectFile).name])
      buildDll = cc[c].buildDll
    else: 
      exefile = splitFile(projectFile).name & platform.os[targetOS].exeExt
      buildDll = ""
    if targetOS == platform.hostOS: 
      exefile = joinPath(splitFile(projectFile).dir, exefile)
    exefile = quoteIfContainsWhite(exefile)
    var it = PStrEntry(toLink.head)
    var objfiles = ""
    while it != nil: 
      add(objfiles, ' ')
      if targetOS == platform.hostOS: 
        add(objfiles, quoteIfContainsWhite(addFileExt(it.data, cc[ccompiler].objExt)))
      else: 
        add(objfiles, quoteIfContainsWhite(addFileExt(it.data, cc[ccompiler].objExt)))
      it = PStrEntry(it.next)
    linkCmd = quoteIfContainsWhite(linkCmd % ["builddll", builddll, 
        "buildgui", buildgui, "options", linkOptions, "objfiles", objfiles, 
        "exefile", exefile, "nimrod", getPrefixDir(), "lib", libpath])
    add(linkCmd, ' ')
    addf(linkCmd, cc[c].linkTmpl, ["builddll", builddll, 
        "buildgui", buildgui, "options", linkOptions, 
        "objfiles", objfiles, "exefile", exefile, 
        "nimrod", quoteIfContainsWhite(getPrefixDir()), 
        "lib", quoteIfContainsWhite(libpath)])
    if not (optCompileOnly in gGlobalOptions): execExternalProgram(linkCmd)
  else: 
    linkCmd = ""
  if optGenScript in gGlobalOptions: 
    app(script, linkCmd)
    app(script, tnl)
    generateScript(projectFile, script)

proc genMappingFiles(list: TLinkedList): PRope = 
  var it = PStrEntry(list.head)
  while it != nil: 
    appf(result, "--file:r\"$1\"$n", [toRope(AddFileExt(it.data, cExt))])
    it = PStrEntry(it.next)

proc writeMapping*(gSymbolMapping: PRope) = 
  if optGenMapping notin gGlobalOptions: return 
  var code = toRope("[C_Files]\n")
  app(code, genMappingFiles(toCompile))
  app(code, genMappingFiles(externalToCompile))
  appf(code, "[Symbols]$n$1", [gSymbolMapping])
  WriteRope(code, joinPath(projectPath, "mapping.txt"))
