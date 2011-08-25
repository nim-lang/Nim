#
#
#         Maintenance program for Nimrod
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(gcc) and defined(windows):
  {.link: "icons/koch.res".}

import
  os, strutils, parseopt

const
  HelpText = """
+-----------------------------------------------------------------+
|         Maintenance program for Nimrod                          |
|             Version $1|
|             (c) 2011 Andreas Rumpf                              |
+-----------------------------------------------------------------+
Build time: $2, $3

Usage:
  koch [options] command [options for command]
Options:
  --help, -h               shows this help and quits
Possible Commands:
  boot [options]           bootstraps with given command line options
  clean                    cleans Nimrod project; removes generated files
  web                      generates the website
  csource [options]        builds the C sources for installation
  zip                      builds the installation ZIP package
  inno [options]           builds the Inno Setup installer (for Windows)
  install                  execute the script 'build.sh' in the current directory
  test, tests              run the testsuite
Boot options:
  -d:release               produce a release version of the compiler
  -d:tinyc                 include the Tiny C backend (not supported on Windows)
  -d:useGnuReadline        use the GNU readline library for interactive mode
                           (not needed on Windows)
  -d:nativeStacktrace      use native stack traces (only for Mac OS X or Linux)
"""

proc exe(f: string): string = return addFileExt(f, ExeExt)

proc exec(cmd: string) =
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE")

proc tryExec(cmd: string): bool =
  echo(cmd)
  result = execShellCmd(cmd) == 0

proc csource(args: string) =
  exec("nimrod cc $1 -r tools/niminst --var:version=$2 csource compiler/nimrod.ini $1" %
       [args, NimrodVersion])

proc zip(args: string) =
  exec("nimrod cc -r tools/niminst --var:version=$# zip compiler/nimrod.ini" %
       NimrodVersion)

proc buildTool(toolname, args: string) =
  exec("nimrod cc $# $#" % [args, toolname])
  copyFile(dest="bin"/ splitFile(toolname).name.exe, source=toolname.exe)

proc inno(args: string) =
  # make sure we have generated the c2nim and niminst executables:
  buildTool("tools/niminst", args)
  buildTool("compiler/c2nim/c2nim", args)
  exec("tools" / "niminst --var:version=$# inno compiler/nimrod" %
       NimrodVersion)

proc install(args: string) =
  exec("sh ./build.sh")

proc web(args: string) =
  exec("nimrod cc -r tools/nimweb.nim web/nimrod --putenv:nimrodversion=$#" %
       NimrodVersion)

# -------------- boot ---------------------------------------------------------

const
  bootOptions = "" # options to pass to the bootstrap process

proc findStartNimrod: string =
  # we try several things before giving up:
  # * bin/nimrod
  # * $PATH/nimrod
  # If these fail, we try to build nimrod with the "build.(sh|bat)" script.
  var nimrod = "nimrod".exe
  result = "bin" / nimrod
  if ExistsFile(result): return
  for dir in split(getEnv("PATH"), PathSep):
    if ExistsFile(dir / nimrod): return nimrod
  when defined(Posix):
    const buildScript = "build.sh"
    if ExistsFile(buildScript):
      if tryExec("./" & buildScript): return "bin" / nimrod
  else:
    const buildScript = "build.bat"
    if ExistsFile(buildScript):
      if tryExec(buildScript): return "bin" / nimrod

  echo("Found no nimrod compiler and every attempt to build one failed!")
  quit("FAILURE")

proc safeRemove(filename: string) =
  if existsFile(filename): removeFile(filename)

proc thVersion(i: int): string =
  result = ("compiler" / "nimrod" & $i).exe

proc copyExe(source, dest: string) =
  safeRemove(dest)
  copyFile(dest=dest, source=source)
  inclFilePermissions(dest, {fpUserExec})

proc boot(args: string) =
  var output = "compiler" / "nimrod".exe
  var finalDest = "bin" / "nimrod".exe

  copyExe(findStartNimrod(), 0.thVersion)
  for i in 0..2:
    echo "iteration: ", i+1
    exec i.thVersion & " cc $# $# compiler" / "nimrod.nim" % [bootOptions, args]
    if sameFileContent(output, i.thVersion):
      copyExe(output, finalDest)
      echo "executables are equal: SUCCESS!"
      return
    copyExe(output, (i+1).thVersion)
  copyExe(output, finalDest)
  echo "[Warning] executables are still not equal"

# -------------- clean --------------------------------------------------------

const
  cleanExt = [
    ".ppu", ".o", ".obj", ".dcu", ".~pas", ".~inc", ".~dsk", ".~dpr",
    ".map", ".tds", ".err", ".bak", ".pyc", ".exe", ".rod", ".pdb", ".idb"
  ]
  ignore = [
    ".bzrignore", "nimrod", "nimrod.exe", "koch", "koch.exe"
  ]

proc cleanAux(dir: string) =
  for kind, path in walkDir(dir):
    case kind
    of pcFile:
      var (dir, name, ext) = splitFile(path)
      if ext == "" or cleanExt.contains(ext):
        if not ignore.contains(name):
          echo "removing: ", path
          removeFile(path)
    of pcDir:
      case splitPath(path).tail
      of "nimcache":
        echo "removing dir: ", path
        removeDir(path)
      of "dist", ".git": nil
      else: cleanAux(path)
    else: nil

proc removePattern(pattern: string) =
  for f in WalkFiles(pattern):
    echo "removing: ", f
    removeFile(f)

proc clean(args: string) =
  if ExistsFile("koch.dat"): removeFile("koch.dat")
  removePattern("web/*.html")
  removePattern("doc/*.html")
  cleanAux(getCurrentDir())
  for kind, path in walkDir(getCurrentDir() / "build"):
    if kind == pcDir:
      echo "removing dir: ", path
      RemoveDir(path)

proc tests(args: string) =
  exec("nimrod cc tests/tester")
  exec("tests/tester reject")
  exec("tests/tester compile")
  exec("tests/tester examples")
  exec("tests/tester run")
  exec("tests/tester merge")

proc showHelp() =
  quit(HelpText % [NimrodVersion & repeatChar(44-len(NimrodVersion)),
                   CompileDate, CompileTime])

var op = initOptParser()
op.next()
case op.kind
of cmdLongOption, cmdShortOption: showHelp()
of cmdArgument:
  case normalize(op.key)
  of "boot": boot(op.cmdLineRest)
  of "clean": clean(op.cmdLineRest)
  of "web": web(op.cmdLineRest)
  of "csource": csource(op.cmdLineRest)
  of "zip": zip(op.cmdLineRest)
  of "inno": inno(op.cmdLineRest)
  of "install": install(op.cmdLineRest)
  of "test", "tests": tests(op.cmdLineRest)
  else: showHelp()
of cmdEnd: showHelp()

