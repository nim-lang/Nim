#
#
#         Maintenance program for Nim
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
#    See doc/koch.txt for documentation.
#

when defined(gcc) and defined(windows):
  when defined(x86):
    {.link: "icons/koch.res".}
  else:
    {.link: "icons/koch_icon.o".}

import
  os, strutils, parseopt, osproc, streams

when defined(withUpdate):
  import httpclient
when defined(haveZipLib):
  import zipfiles

const
  HelpText = """
+-----------------------------------------------------------------+
|         Maintenance program for Nim                             |
|             Version $1|
|             (c) 2014 Andreas Rumpf                              |
+-----------------------------------------------------------------+
Build time: $2, $3

Usage:
  koch [options] command [options for command]
Options:
  --help, -h               shows this help and quits
Possible Commands:
  boot [options]           bootstraps with given command line options
  install [dir]            installs to given directory
  clean                    cleans Nimrod project; removes generated files
  web                      generates the website
  csource [options]        builds the C sources for installation
  zip                      builds the installation ZIP package
  inno [options]           builds the Inno Setup installer (for Windows)
  tests [options]          run the testsuite
  update                   updates nim to the latest version from github
                           (compile koch with -d:withUpdate to enable)
  temp options             creates a temporary compiler for testing
Boot options:
  -d:release               produce a release version of the compiler
  -d:tinyc                 include the Tiny C backend (not supported on Windows)
  -d:useGnuReadline        use the GNU readline library for interactive mode
                           (not needed on Windows)
  -d:nativeStacktrace      use native stack traces (only for Mac OS X or Linux)
  -d:noCaas                build Nimrod without CAAS support
  -d:avoidTimeMachine      only for Mac OS X, excludes nimcache dir from backups
"""

proc exe(f: string): string = return addFileExt(f, ExeExt)

proc findNim(): string =
  var nim = "nim".exe
  result = "bin" / nim
  if existsFile(result): return
  for dir in split(getEnv("PATH"), PathSep):
    if existsFile(dir / nim): return dir / nim
  # assume there is a symlink to the exe or something:
  return nim

proc exec(cmd: string) =
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE")

proc tryExec(cmd: string): bool = 
  echo(cmd)
  result = execShellCmd(cmd) == 0

const
  compileNimInst = "-d:useLibzipSrc tools/niminst/niminst"

proc csource(args: string) = 
  exec("$4 cc $1 -r $3 --var:version=$2 csource compiler/nim.ini $1" %
       [args, NimVersion, compileNimInst, findNim()])

proc zip(args: string) = 
  exec("$3 cc -r $2 --var:version=$1 zip compiler/nim.ini" %
       [NimVersion, compileNimInst, findNim()])
  
proc buildTool(toolname, args: string) = 
  exec("$# cc $# $#" % [findNim(), args, toolname])
  copyFile(dest="bin"/ splitFile(toolname).name.exe, source=toolname.exe)

proc inno(args: string) =
  # make sure we have generated the niminst executables:
  buildTool("tools/niminst/niminst", args)
  buildTool("tools/nimgrep", args)
  exec("tools" / "niminst" / "niminst --var:version=$# inno compiler/nim" % 
       NimVersion)

proc install(args: string) = 
  exec("$# cc -r $# --var:version=$# scripts compiler/nim.ini" %
       [findNim(), compileNimInst, NimVersion])
  exec("sh ./install.sh $#" % args)

proc web(args: string) =
  exec("$# cc -r tools/nimweb.nim web/nim --putenv:nimversion=$#" % 
       [findNim(), NimVersion])

# -------------- boot ---------------------------------------------------------

const
  bootOptions = "" # options to pass to the bootstrap process

proc findStartNim: string = 
  # we try several things before giving up:
  # * bin/nim
  # * $PATH/nim
  # * bin/nimrod
  # * $PATH/nimrod
  # If these fail, we try to build nim with the "build.(sh|bat)" script.
  var nim = "nim".exe
  result = "bin" / nim
  if existsFile(result): return
  for dir in split(getEnv("PATH"), PathSep):
    if existsFile(dir / nim): return dir / nim

  # try the old "nimrod.exe":
  var nimrod = "nimrod".exe
  result = "bin" / nimrod
  if existsFile(result): return
  for dir in split(getEnv("PATH"), PathSep):
    if existsFile(dir / nim): return dir / nimrod

  when defined(Posix):
    const buildScript = "build.sh"
    if existsFile(buildScript): 
      if tryExec("./" & buildScript): return "bin" / nim
  else:
    const buildScript = "build.bat"
    if existsFile(buildScript): 
      if tryExec(buildScript): return "bin" / nim

  echo("Found no nim compiler and every attempt to build one failed!")
  quit("FAILURE")

proc safeRemove(filename: string) = 
  if existsFile(filename): removeFile(filename)

proc thVersion(i: int): string = 
  result = ("compiler" / "nim" & $i).exe

proc copyExe(source, dest: string) =
  safeRemove(dest)
  copyFile(dest=dest, source=source)
  inclFilePermissions(dest, {fpUserExec})
  
proc boot(args: string) =
  var output = "compiler" / "nim".exe
  var finalDest = "bin" / "nim".exe
  
  copyExe(findStartNim(), 0.thVersion)
  for i in 0..2:
    echo "iteration: ", i+1
    exec i.thVersion & " c $# $# compiler" / "nim.nim" % [bootOptions, args]
    if sameFileContent(output, i.thVersion):
      copyExe(output, finalDest)
      echo "executables are equal: SUCCESS!"
      return
    copyExe(output, (i+1).thVersion)
  copyExe(output, finalDest)
  when not defined(windows): echo "[Warning] executables are still not equal"

# -------------- clean --------------------------------------------------------

const
  cleanExt = [
    ".ppu", ".o", ".obj", ".dcu", ".~pas", ".~inc", ".~dsk", ".~dpr",
    ".map", ".tds", ".err", ".bak", ".pyc", ".exe", ".rod", ".pdb", ".idb",
    ".idx", ".ilk"
  ]
  ignore = [
    ".bzrignore", "nim", "nim.exe", "koch", "koch.exe", ".gitignore"
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
      of "dist", ".git", "icons": discard
      else: cleanAux(path)
    else: discard

proc removePattern(pattern: string) = 
  for f in walkFiles(pattern): 
    echo "removing: ", f
    removeFile(f)

proc clean(args: string) = 
  if existsFile("koch.dat"): removeFile("koch.dat")
  removePattern("web/*.html")
  removePattern("doc/*.html")
  cleanAux(getCurrentDir())
  for kind, path in walkDir(getCurrentDir() / "build"):
    if kind == pcDir: 
      echo "removing dir: ", path
      removeDir(path)

# -------------- update -------------------------------------------------------

when defined(withUpdate):
  when defined(windows):
    {.warning: "Windows users: Make sure to run 'koch update' in Bash.".}

  proc update(args: string) =
    when defined(windows):
      echo("Windows users: Make sure to be running this in Bash. ",
           "If you aren't, press CTRL+C now.")

    var thisDir = getAppDir()
    var git = findExe("git")
    echo("Checking for git repo and git executable...")
    if existsDir(thisDir & "/.git") and git != "":
      echo("Git repo found!")
      # use git to download latest source
      echo("Checking for updates...")
      discard startCmd(git & " fetch origin master")
      var procs = startCmd(git & " diff origin/master master")
      var errcode = procs.waitForExit()
      var output = readLine(procs.outputStream)
      echo(output)
      if errcode == 0:
        if output == "":
          # No changes
          echo("No update. Exiting...")
          return
        else:
          echo("Fetching updates from repo...")
          var pullout = execCmdEx(git & " pull origin master")
          if pullout[1] != 0:
            quit("An error has occured.")
          else:
            if pullout[0].startsWith("Already up-to-date."):
              quit("No new changes fetched from the repo. " &
                   "Local branch must be ahead of it. Exiting...")
      else:
        quit("An error has occured.")
      
    else:
      echo("No repo or executable found!")
      when defined(haveZipLib):
        echo("Falling back.. Downloading source code from repo...")
        # use dom96's httpclient to download zip
        downloadFile("https://github.com/Araq/Nimrod/zipball/master",
                     thisDir / "update.zip")
        try:
          echo("Extracting source code from archive...")
          var zip: TZipArchive
          discard open(zip, thisDir & "/update.zip", fmRead)
          extractAll(zip, thisDir & "/")
        except:
          quit("Error reading archive.")
      else:
        quit("No failback available. Exiting...")
    
    echo("Starting update...")
    boot(args)
    echo("Update complete!")

# -------------- tests --------------------------------------------------------

template `|`(a, b): expr = (if a.len > 0: a else: b)

proc tests(args: string) =
  # we compile the tester with taintMode:on to have a basic
  # taint mode test :-)
  exec "nim cc --taintMode:on tests/testament/tester"
  let tester = quoteShell(getCurrentDir() / "tests/testament/tester".exe)
  exec tester & " " & (args|"all")
  exec tester & " html"

proc temp(args: string) =
  var output = "compiler" / "nim".exe
  var finalDest = "bin" / "nim_temp".exe
  exec("nim c compiler" / "nim")
  copyExe(output, finalDest)
  if args.len > 0: exec(finalDest & " " & args)

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
  of "csource", "csources": csource(op.cmdLineRest)
  of "zip": zip(op.cmdLineRest)
  of "inno": inno(op.cmdLineRest)
  of "install": install(op.cmdLineRest)
  of "test", "tests": tests(op.cmdLineRest)
  of "update": 
    when defined(withUpdate):
      update(op.cmdLineRest)
    else:
      quit "this Koch has not been compiled with -d:withUpdate"
  of "temp": temp(op.cmdLineRest)
  else: showHelp()
of cmdEnd: showHelp()

