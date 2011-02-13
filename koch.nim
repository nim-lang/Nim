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
  inno [options]           builds the Inno Setup installer
Boot options:
  -d:release               produce a release version of the compiler
  -d:tinyc                 include the Tiny C backend (not supported on Windows)
  -d:useGnuReadline        use the GNU readline library for interactive mode
                           (not supported on Windows)
"""

proc exe(f: string): string = return addFileExt(f, ExeExt)

proc exec(cmd: string) =
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE")

proc tryExec(cmd: string): bool = 
  echo(cmd)
  result = execShellCmd(cmd) == 0

proc csource(args: string) = 
  exec("nimrod cc $1 -r tools/niminst --var:version=$2 csource rod/nimrod $1" %
       [args, NimrodVersion])

proc zip(args: string) = 
  exec("nimrod cc -r tools/niminst --var:version=$# zip rod/nimrod" %
       NimrodVersion)
  
proc buildTool(toolname, args: string) = 
  exec("nimrod cc $# $#" % [args, toolname])
  copyFile(dest="bin"/ splitFile(toolname).name.exe, source=toolname.exe)

proc inno(args: string) =
  # make sure we have generated the c2nim and niminst executables:
  buildTool("tools/niminst", args)
  buildTool("rod/c2nim/c2nim", args)
  exec("tools" / "niminst --var:version=$# inno rod/nimrod" % NimrodVersion)

proc install(args: string) = 
  exec("sh ./build.sh")

proc web(args: string) =
  exec("nimrod cc -r tools/nimweb.nim web/nimrod --putenv:nimrodversion=$#" %
       NimrodVersion)

# -------------- nim ----------------------------------------------------------

proc compileNimCmd(args: string): string = 
  var cwd = getCurrentDir()
  result = ("fpc -Cs16777216 -gl -bl -Crtoi -Sgidh -vw -Se1 $4 -o\"$1\" " &
            "-FU\"$2\" \"$3\"") % [cwd / "bin" / "nim".exe, 
                                   cwd / "obj",
                                   cwd / "nim" / "nimrod.pas",
                                   args]

proc nim(args: string) = exec(compileNimCmd(args))

# -------------- boot ---------------------------------------------------------

const
  bootOptions = "" # options to pass to the bootstrap process

proc findStartNimrod: string = 
  # we try several things before giving up:
  # * bin/nimrod
  # * $PATH/nimrod
  # * bin/nim
  # If these fail, we build nimrod with the "build.sh" script
  # (but only on UNIX). Otherwise we try to compile "nim" with FPC 
  # and use "bin/nim".
  var nimrod = "nimrod".exe
  result = "bin" / nimrod
  if ExistsFile(result): return
  for dir in split(getEnv("PATH"), PathSep):
    if ExistsFile(dir / nimrod): return nimrod
  result = "bin" / "nim".exe
  if ExistsFile(result): return
  when defined(Posix):
    const buildScript = "build.sh"
    if ExistsFile(buildScript): 
      if tryExec("./" & buildScript): return "bin" / nimrod
  
  if tryExec(compileNimCmd("")): return 
  echo("Found no nimrod compiler and every attempt to build one failed!")
  quit("FAILURE")

proc safeRemove(filename: string) = 
  if existsFile(filename): removeFile(filename)

proc bootIteration(args: string): bool = 
  var nimrod1 = "rod" / "nimrod1".exe
  safeRemove(nimrod1)
  moveFile(dest=nimrod1, source="rod" / "nimrod".exe)
  exec "rod" / "nimrod1 cc $# $# rod/nimrod.nim" % [bootOptions, args]
  # Nimrod does not produce an executable again if nothing changed. That's ok:
  result = sameFileContent("rod" / "nimrod".exe, nimrod1)
  var dest = "bin" / "nimrod".exe
  safeRemove(dest)
  copyFile(dest=dest, source="rod" / "nimrod".exe)
  inclFilePermissions(dest, {fpUserExec})
  safeRemove(nimrod1)
  if result: echo "executables are equal: SUCCESS!"

proc boot(args: string) =
  echo "iteration: 1"
  exec findStartNimrod() & " cc $# $# rod" / "nimrod.nim" % [bootOptions, args]
  echo "iteration: 2"
  if not bootIteration(args):
    echo "executables are not equal: compile once again..."
    if not bootIteration(args):
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
      of "dist", ".bzr":
        nil
      else:
        cleanAux(path)
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
  of "nim": nim(op.cmdLineRest)
  else: showHelp()
of cmdEnd: showHelp()

