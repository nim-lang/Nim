#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, options, msgs, tinyc

{.compile: "../tinyc/libtcc.c".}

proc tinyCErrorHandler(closure: pointer, msg: cstring) {.cdecl.} =
  rawMessage(errGenerated, $msg)

proc initTinyCState: PccState =
  result = openCCState()
  setErrorFunc(result, nil, tinyCErrorHandler)

var
  gTinyC = initTinyCState()
  libIncluded = false

proc addFile(filename: string) =
  if addFile(gTinyC, filename) != 0'i32:
    rawMessage(errCannotOpenFile, filename)

proc setupEnvironment =
  when defined(amd64):
    defineSymbol(gTinyC, "__x86_64__", nil)
  elif defined(i386):
    defineSymbol(gTinyC, "__i386__", nil)
  when defined(linux):
    defineSymbol(gTinyC, "__linux__", nil)
    defineSymbol(gTinyC, "__linux", nil)
  var nimrodDir = getPrefixDir()

  addIncludePath(gTinyC, libpath)
  when defined(windows):
    addSysincludePath(gTinyC, nimrodDir / "tinyc/win32/include")
  addSysincludePath(gTinyC, nimrodDir / "tinyc/include")
  when defined(windows):
    defineSymbol(gTinyC, "_WIN32", nil)
    # we need Mingw's headers too:
    var gccbin = getConfigVar("gcc.path") % ["nimrod", nimrodDir]
    addSysincludePath(gTinyC, gccbin /../ "include")
    #addFile(nimrodDir / r"tinyc\win32\wincrt1.o")
    addFile(nimrodDir / r"tinyc\win32\alloca86.o")
    addFile(nimrodDir / r"tinyc\win32\chkstk.o")
    #addFile(nimrodDir / r"tinyc\win32\crt1.o")

    #addFile(nimrodDir / r"tinyc\win32\dllcrt1.o")
    #addFile(nimrodDir / r"tinyc\win32\dllmain.o")
    addFile(nimrodDir / r"tinyc\win32\libtcc1.o")

    #addFile(nimrodDir / r"tinyc\win32\lib\crt1.c")
    #addFile(nimrodDir / r"tinyc\lib\libtcc1.c")
  else:
    addSysincludePath(gTinyC, "/usr/include")
    when defined(amd64):
      addSysincludePath(gTinyC, "/usr/include/x86_64-linux-gnu")

proc compileCCode*(ccode: string) =
  if not libIncluded:
    libIncluded = true
    setupEnvironment()
  discard compileString(gTinyC, ccode)

proc run*() =
  var a: array[0..1, cstring]
  a[0] = ""
  a[1] = ""
  var err = tinyc.run(gTinyC, 0'i32, cast[cstringArray](addr(a))) != 0'i32
  closeCCState(gTinyC)
  if err: rawMessage(errExecutionOfProgramFailed, "")

