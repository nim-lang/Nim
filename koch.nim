#
#
#         Maintenance program for Nim
#        (c) Copyright 2015 Andreas Rumpf
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

const VersionAsString = system.NimVersion #"0.10.2"

when defined(withUpdate):
  import httpclient
when defined(haveZipLib):
  import zipfiles

const
  HelpText = """
+-----------------------------------------------------------------+
|         Maintenance program for Nim                             |
|             Version $1|
|             (c) 2015 Andreas Rumpf                              |
+-----------------------------------------------------------------+
Build time: $2, $3

Usage:
  koch [options] command [options for command]
Options:
  --help, -h               shows this help and quits
Possible Commands:
  boot [options]           bootstraps with given command line options
  install [bindir]         installs to given directory; Unix only!
  clean                    cleans Nim project; removes generated files
  web [options]            generates the website and the full documentation
  website [options]        generates only the website
  csource [options]        builds the C sources for installation
  pdf                      builds the PDF documentation
  zip                      builds the installation ZIP package
  nsis [options]           builds the NSIS Setup installer (for Windows)
  tests [options]          run the testsuite
  update                   updates nim to the latest version from github
                           (compile koch with -d:withUpdate to enable)
  temp options             creates a temporary compiler for testing
  winrelease               creates a release (for coredevs only)
Boot options:
  -d:release               produce a release version of the compiler
  -d:tinyc                 include the Tiny C backend (not supported on Windows)
  -d:useGnuReadline        use the GNU readline library for interactive mode
                           (not needed on Windows)
  -d:nativeStacktrace      use native stack traces (only for Mac OS X or Linux)
  -d:noCaas                build Nim without CAAS support
  -d:avoidTimeMachine      only for Mac OS X, excludes nimcache dir from backups
Web options:
  --googleAnalytics:UA-... add the given google analytics code to the docs. To
                           build the official docs, use UA-48159761-1
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

proc exec(cmd: string, errorcode: int = QuitFailure) =
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE", errorcode)

proc tryExec(cmd: string): bool = 
  echo(cmd)
  result = execShellCmd(cmd) == 0

proc safeRemove(filename: string) =
  if existsFile(filename): removeFile(filename)

proc copyExe(source, dest: string) =
  safeRemove(dest)
  copyFile(dest=dest, source=source)
  inclFilePermissions(dest, {fpUserExec})

const
  compileNimInst = "-d:useLibzipSrc tools/niminst/niminst"

proc csource(args: string) = 
  exec("$4 cc $1 -r $3 --var:version=$2 --var:mingw=none csource --main:compiler/nim.nim compiler/installer.ini $1" %
       [args, VersionAsString, compileNimInst, findNim()])

proc zip(args: string) =
  exec("$3 cc -r $2 --var:version=$1 --var:mingw=none --main:compiler/nim.nim scripts compiler/installer.ini" %
       [VersionAsString, compileNimInst, findNim()])
  exec("$# --var:version=$# --var:mingw=none --main:compiler/nim.nim zip compiler/installer.ini" %
       ["tools/niminst/niminst".exe, VersionAsString])

proc buildTool(toolname, args: string) =
  exec("$# cc $# $#" % [findNim(), args, toolname])
  copyFile(dest="bin"/ splitFile(toolname).name.exe, source=toolname.exe)

proc nsis(args: string) =
  # make sure we have generated the niminst executables:
  buildTool("tools/niminst/niminst", args)
  buildTool("tools/nimgrep", args)
  # produce 'nimrod_debug.exe':
  exec "nim c compiler" / "nim.nim"
  copyExe("compiler/nim".exe, "bin/nim_debug".exe)
  exec(("tools" / "niminst" / "niminst --var:version=$# --var:mingw=mingw$#" &
        " nsis compiler/nim") % [VersionAsString, $(sizeof(pointer)*8)])

proc install(args: string) = 
  exec("$# cc -r $# --var:version=$# --var:mingw=none --main:compiler/nim.nim scripts compiler/installer.ini" %
       [findNim(), compileNimInst, VersionAsString])
  exec("sh ./install.sh $#" % args)

proc web(args: string) =
  exec("$# cc -r tools/nimweb.nim $# web/website.ini --putenv:nimversion=$#" %
       [findNim(), args, VersionAsString])

proc website(args: string) =
  exec("$# cc -r tools/nimweb.nim $# --website web/website.ini --putenv:nimversion=$#" %
       [findNim(), args, VersionAsString])

proc pdf(args="") =
  exec("$# cc -r tools/nimweb.nim $# --pdf web/website.ini --putenv:nimversion=$#" %
       [findNim(), args, VersionAsString])

# -------------- boot ---------------------------------------------------------

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

proc thVersion(i: int): string = 
  result = ("compiler" / "nim" & $i).exe
  
proc boot(args: string) =
  var output = "compiler" / "nim".exe
  var finalDest = "bin" / "nim".exe
  # default to use the 'c' command:
  let bootOptions = if args.len == 0 or args.startsWith("-"): "c" else: ""
  
  copyExe(findStartNim(), 0.thVersion)
  for i in 0..2:
    echo "iteration: ", i+1
    exec i.thVersion & " $# $# compiler" / "nim.nim" % [bootOptions, args]
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
            quit("An error has occurred.")
          else:
            if pullout[0].startsWith("Already up-to-date."):
              quit("No new changes fetched from the repo. " &
                   "Local branch must be ahead of it. Exiting...")
      else:
        quit("An error has occurred.")
      
    else:
      echo("No repo or executable found!")
      when defined(haveZipLib):
        echo("Falling back.. Downloading source code from repo...")
        # use dom96's httpclient to download zip
        downloadFile("https://github.com/Araq/Nim/zipball/master",
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

# -------------- builds a release ---------------------------------------------

proc run7z(platform: string, patterns: varargs[string]) =
  const tmpDir = "nim-" & VersionAsString
  createDir tmpDir
  try:
    for pattern in patterns:
      for f in walkFiles(pattern):
        if "nimcache" notin f:
          copyFile(f, tmpDir / f)
    exec("7z a -tzip $1-$2.zip $1" % [tmpDir, platform])
  finally:
    removeDir tmpDir

proc winRelease() =
  boot(" -d:release")
  #buildTool("tools/niminst/niminst", " -d:release")
  buildTool("tools/nimgrep", " -d:release")
  buildTool("compiler/nimfix/nimfix", " -d:release")

  run7z("win32", "bin/nim.exe", "bin/c2nim.exe", "bin/nimgrep.exe",
        "bin/nimfix.exe",
        "bin/nimble.exe", "bin/*.dll",
        "config", "dist/*.dll", "examples", "lib",
        "readme.txt", "contributors.txt", "copying.txt")
  # second step: XXX build 64 bit version

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
  # 125 is the magic number to tell git bisect to skip the current
  # commit.
  exec("nim c compiler" / "nim", 125)
  copyExe(output, finalDest)
  if args.len > 0: exec(finalDest & " " & args)

proc showHelp() = 
  quit(HelpText % [VersionAsString & spaces(44-len(VersionAsString)), 
                   CompileDate, CompileTime], QuitSuccess)

var op = initOptParser()
op.next()
case op.kind
of cmdLongOption, cmdShortOption: showHelp()
of cmdArgument:
  case normalize(op.key)
  of "boot": boot(op.cmdLineRest)
  of "clean": clean(op.cmdLineRest)
  of "web": web(op.cmdLineRest)
  of "website": website(op.cmdLineRest & " --googleAnalytics:UA-48159761-1")
  of "web0":
    # undocumented command for Araq-the-merciful:
    web(op.cmdLineRest & " --googleAnalytics:UA-48159761-1")
  of "pdf": pdf()
  of "csource", "csources": csource(op.cmdLineRest)
  of "zip": zip(op.cmdLineRest)
  of "nsis": nsis(op.cmdLineRest)
  of "install": install(op.cmdLineRest)
  of "test", "tests": tests(op.cmdLineRest)
  of "update":
    when defined(withUpdate):
      update(op.cmdLineRest)
    else:
      quit "this Koch has not been compiled with -d:withUpdate"
  of "temp": temp(op.cmdLineRest)
  of "winrelease": winRelease()
  else: showHelp()
of cmdEnd: showHelp()
