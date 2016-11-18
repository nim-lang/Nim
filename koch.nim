#
#
#         Maintenance program for Nim
#        (c) Copyright 2016 Andreas Rumpf
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

when defined(amd64) and defined(windows) and defined(vcc):
  {.link: "icons/koch-amd64-windows-vcc.res" .}
when defined(i386) and defined(windows) and defined(vcc):
  {.link: "icons/koch-i386-windows-vcc.res" .}

import
  os, strutils, parseopt, osproc, streams

const VersionAsString = system.NimVersion #"0.10.2"

const
  HelpText = """
+-----------------------------------------------------------------+
|         Maintenance program for Nim                             |
|             Version $1|
|             (c) 2016 Andreas Rumpf                              |
+-----------------------------------------------------------------+
Build time: $2, $3

Usage:
  koch [options] command [options for command]
Options:
  --help, -h               shows this help and quits
Possible Commands:
  boot [options]           bootstraps with given command line options
  distrohelper [bindir]    helper for distro packagers
  geninstall               generate ./install.sh; Unix only!
  testinstall              test tar.xz package; Unix only! Only for devs!
  clean                    cleans Nim project; removes generated files
  web [options]            generates the website and the full documentation
  website [options]        generates only the website
  csource [options]        builds the C sources for installation
  pdf                      builds the PDF documentation
  zip                      builds the installation ZIP package
  xz                       builds the installation XZ package
  nsis [options]           builds the NSIS Setup installer (for Windows)
  tests [options]          run the testsuite
  temp options             creates a temporary compiler for testing
  winrelease               creates a release (for coredevs only)
  nimble                   builds the Nimble tool
  tools                    builds Nim related tools
  pushcsource              push generated C sources to its repo! Only for devs!
Boot options:
  -d:release               produce a release version of the compiler
  -d:tinyc                 include the Tiny C backend (not supported on Windows)
  -d:useLinenoise          use the linenoise library for interactive mode
                           (not needed on Windows)
  -d:nativeStacktrace      use native stack traces (only for Mac OS X or Linux)
  -d:noCaas                build Nim without CAAS support
  -d:avoidTimeMachine      only for Mac OS X, excludes nimcache dir from backups
Web options:
  --googleAnalytics:UA-... add the given google analytics code to the docs. To
                           build the official docs, use UA-48159761-1
"""

proc exe(f: string): string =
  result = addFileExt(f, ExeExt)
  when defined(windows):
    result = result.replace('/','\\')

proc findNim(): string =
  var nim = "nim".exe
  result = "bin" / nim
  if existsFile(result): return
  for dir in split(getEnv("PATH"), PathSep):
    if existsFile(dir / nim): return dir / nim
  # assume there is a symlink to the exe or something:
  return nim

proc exec(cmd: string, errorcode: int = QuitFailure, additionalPath = "") =
  let prevPath = getEnv("PATH")
  if additionalPath.len > 0:
    var absolute = additionalPATH
    if not absolute.isAbsolute:
      absolute = getCurrentDir() / absolute
    echo("Adding to $PATH: ", absolute)
    putEnv("PATH", prevPath & PathSep & absolute)
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE", errorcode)
  putEnv("PATH", prevPath)

proc nimexec(cmd: string) =
  exec findNim() & " " & cmd

proc execCleanPath(cmd: string,
                   additionalPath = ""; errorcode: int = QuitFailure) =
  # simulate a poor man's virtual environment
  let prevPath = getEnv("PATH")
  when defined(windows):
    let CleanPath = r"$1\system32;$1;$1\System32\Wbem" % getEnv"SYSTEMROOT"
  else:
    const CleanPath = r"/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"
  putEnv("PATH", CleanPath & PathSep & additionalPath)
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE", errorcode)
  putEnv("PATH", prevPath)

proc testUnixInstall() =
  let oldCurrentDir = getCurrentDir()
  try:
    let destDir = getTempDir()
    copyFile("build/nim-$1.tar.xz" % VersionAsString,
             destDir / "nim-$1.tar.xz" % VersionAsString)
    setCurrentDir(destDir)
    execCleanPath("tar -xJf nim-$1.tar.xz" % VersionAsString)
    setCurrentDir("nim-$1" % VersionAsString)
    execCleanPath("sh build.sh")
    # first test: try if './bin/nim --version' outputs something sane:
    let output = execProcess("./bin/nim --version").splitLines
    if output.len > 0 and output[0].contains(VersionAsString):
      echo "Version check: success"
      execCleanPath("./bin/nim c koch.nim")
      execCleanPath("./koch boot -d:release", destDir / "bin")
      # check the docs build:
      execCleanPath("./koch web", destDir / "bin")
      # check nimble builds:
      execCleanPath("./bin/nim e install_tools.nims")
      # check the tests work:
      execCleanPath("./koch tests", destDir / "bin")
    else:
      echo "Version check: failure"
  finally:
    setCurrentDir oldCurrentDir

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
  compileNimInst = "tools/niminst/niminst"

proc csource(args: string) =
  nimexec(("cc $1 -r $3 --var:version=$2 --var:mingw=none csource " &
           "--main:compiler/nim.nim compiler/installer.ini $1") %
       [args, VersionAsString, compileNimInst])

proc bundleNimbleSrc() =
  ## bunldeNimbleSrc() bundles a specific Nimble commit with the tarball. We
  ## always bundle the latest official release.
  if dirExists("dist/nimble/.git"):
    exec("git --git-dir dist/nimble/.git pull")
  else:
    exec("git clone https://github.com/nim-lang/nimble.git dist/nimble")
  let tags = execProcess("git --git-dir dist/nimble/.git tag -l v*").splitLines
  let tag = tags[^1]
  exec("git --git-dir dist/nimble/.git checkout " & tag)

proc bundleNimbleExe() =
  bundleNimbleSrc()
  # now compile Nimble and copy it to $nim/bin for the installer.ini
  # to pick it up:
  nimexec("c dist/nimble/src/nimble.nim")
  copyExe("dist/nimble/src/nimble".exe, "bin/nimble".exe)

proc buildNimble() =
  ## buildNimble() builds Nimble for the building via "github". As such, we
  ## choose the most recent commit of Nimble too.
  var installDir = "dist/nimble"
  if dirExists("dist/nimble/.git"):
    exec("git --git-dir dist/nimble/.git pull")
  else:
    # if dist/nimble exist, but is not a git repo, don't mess with it:
    if dirExists(installDir):
      var id = 0
      while dirExists("dist/nimble" & $id):
        inc id
      installDir = "dist/nimble" & $id
    exec("git clone https://github.com/nim-lang/nimble.git " & installDir)
  nimexec("c " & installDir / "src/nimble.nim")
  copyExe(installDir / "src/nimble".exe, "bin/nimble".exe)

proc bundleNimsuggest(buildExe: bool) =
  if buildExe:
    nimexec("c --noNimblePath -d:release -p:compiler tools/nimsuggest/nimsuggest.nim")
    copyExe("tools/nimsuggest/nimsuggest".exe, "bin/nimsuggest".exe)
    removeFile("tools/nimsuggest/nimsuggest".exe)

proc bundleWinTools() =
  nimexec("c tools/finish.nim")
  copyExe("tools/finish".exe, "finish".exe)
  removeFile("tools/finish".exe)
  nimexec("c -o:bin/vccexe.exe tools/vccenv/vccexe")

proc zip(args: string) =
  bundleNimbleSrc()
  bundleNimsuggest(false)
  bundleWinTools()
  nimexec("cc -r $2 --var:version=$1 --var:mingw=none --main:compiler/nim.nim scripts compiler/installer.ini" %
       [VersionAsString, compileNimInst])
  exec("$# --var:version=$# --var:mingw=none --main:compiler/nim.nim zip compiler/installer.ini" %
       ["tools/niminst/niminst".exe, VersionAsString])

proc xz(args: string) =
  bundleNimbleSrc()
  bundleNimsuggest(false)
  nimexec("cc -r $2 --var:version=$1 --var:mingw=none --main:compiler/nim.nim scripts compiler/installer.ini" %
       [VersionAsString, compileNimInst])
  exec("$# --var:version=$# --var:mingw=none --main:compiler/nim.nim xz compiler/installer.ini" %
       ["tools" / "niminst" / "niminst".exe, VersionAsString])

proc buildTool(toolname, args: string) =
  nimexec("cc $# $#" % [args, toolname])
  copyFile(dest="bin"/ splitFile(toolname).name.exe, source=toolname.exe)

proc buildTools() =
  let nimsugExe = "bin/nimsuggest".exe
  nimexec "c --noNimblePath -p:compiler -d:release -o:" & nimsugExe &
      " tools/nimsuggest/nimsuggest.nim"

  let nimgrepExe = "bin/nimgrep".exe
  nimexec "c -o:" & nimgrepExe & " tools/nimgrep.nim"
  if dirExists"dist/nimble":
    let nimbleExe = "bin/nimble".exe
    nimexec "c --noNimblePath -p:compiler -o:" & nimbleExe &
        " dist/nimble/src/nimble.nim"
  else:
    buildNimble()

proc nsis(args: string) =
  bundleNimbleExe()
  bundleNimsuggest(true)
  bundleWinTools()
  # make sure we have generated the niminst executables:
  buildTool("tools/niminst/niminst", args)
  #buildTool("tools/nimgrep", args)
  # produce 'nim_debug.exe':
  #exec "nim c compiler" / "nim.nim"
  #copyExe("compiler/nim".exe, "bin/nim_debug".exe)
  exec(("tools" / "niminst" / "niminst --var:version=$# --var:mingw=mingw$#" &
        " nsis compiler/installer.ini") % [VersionAsString, $(sizeof(pointer)*8)])

proc geninstall(args="") =
  nimexec("cc -r $# --var:version=$# --var:mingw=none --main:compiler/nim.nim scripts compiler/installer.ini $#" %
       [compileNimInst, VersionAsString, args])

proc install(args: string) =
  geninstall()
  exec("sh ./install.sh $#" % args)

proc web(args: string) =
  nimexec("js tools/dochack/dochack.nim")
  nimexec("cc -r tools/nimweb.nim $# web/website.ini --putenv:nimversion=$#" %
       [args, VersionAsString])

proc website(args: string) =
  nimexec("cc -r tools/nimweb.nim $# --website web/website.ini --putenv:nimversion=$#" %
       [args, VersionAsString])

proc pdf(args="") =
  exec("$# cc -r tools/nimweb.nim $# --pdf web/website.ini --putenv:nimversion=$#" %
       [findNim(), args, VersionAsString], additionalPATH=findNim().splitFile.dir)

# -------------- boot ---------------------------------------------------------

proc findStartNim: string =
  # we try several things before giving up:
  # * bin/nim
  # * $PATH/nim
  # If these fail, we try to build nim with the "build.(sh|bat)" script.
  var nim = "nim".exe
  result = "bin" / nim
  if existsFile(result): return
  for dir in split(getEnv("PATH"), PathSep):
    if existsFile(dir / nim): return dir / nim

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
  let smartNimcache = if "release" in args: "nimcache/release" else: "nimcache/debug"

  copyExe(findStartNim(), 0.thVersion)
  for i in 0..2:
    echo "iteration: ", i+1
    exec i.thVersion & " $# $# --nimcache:$# compiler" / "nim.nim" % [bootOptions, args,
        smartNimcache]
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
      var (_, name, ext) = splitFile(path)
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
  removePattern("web/*.html")
  removePattern("doc/*.html")
  cleanAux(getCurrentDir())
  for kind, path in walkDir(getCurrentDir() / "build"):
    if kind == pcDir:
      echo "removing dir: ", path
      removeDir(path)

# -------------- builds a release ---------------------------------------------

proc winRelease() =
  exec(r"call ci\nsis_build.bat " & VersionAsString)

# -------------- tests --------------------------------------------------------

template `|`(a, b): string = (if a.len > 0: a else: b)

proc tests(args: string) =
  # we compile the tester with taintMode:on to have a basic
  # taint mode test :-)
  nimexec "cc --taintMode:on tests/testament/tester"
  # Since tests take a long time (on my machine), and we want to defy Murhpys
  # law - lets make sure the compiler really is freshly compiled!
  nimexec "c --lib:lib -d:release --opt:speed compiler/nim.nim"
  let tester = quoteShell(getCurrentDir() / "tests/testament/tester".exe)
  let success = tryExec tester & " " & (args|"all")
  if not existsEnv("TRAVIS") and not existsEnv("APPVEYOR"):
    exec tester & " html"
  if not success:
    quit("tests failed", QuitFailure)

proc temp(args: string) =
  proc splitArgs(a: string): (string, string) =
    # every --options before the command (indicated by starting
    # with not a dash) is part of the bootArgs, the rest is part
    # of the programArgs:
    let args = os.parseCmdLine a
    result = ("", "")
    var i = 0
    while i < args.len and args[i][0] == '-':
      result[0].add " " & quoteShell(args[i])
      inc i
    while i < args.len:
      result[1].add " " & quoteShell(args[i])
      inc i

  var output = "compiler" / "nim".exe
  var finalDest = "bin" / "nim_temp".exe
  # 125 is the magic number to tell git bisect to skip the current
  # commit.
  let (bootArgs, programArgs) = splitArgs(args)
  exec("nim c " & bootArgs & " compiler" / "nim", 125)
  copyExe(output, finalDest)
  if programArgs.len > 0: exec(finalDest & " " & programArgs)

proc copyDir(src, dest: string) =
  for kind, path in walkDir(src, relative=true):
    case kind
    of pcDir: copyDir(dest / path, src / path)
    of pcFile:
      createDir(dest)
      copyFile(src / path, dest / path)
    else: discard

proc pushCsources() =
  if not dirExists("../csources/.git"):
    quit "[Error] no csources git repository found"
  csource("-d:release")
  let cwd = getCurrentDir()
  try:
    copyDir("build/c_code", "../csources/c_code")
    copyFile("build/build.sh", "../csources/build.sh")
    copyFile("build/build.bat", "../csources/build.bat")
    copyFile("build/build64.bat", "../csources/build64.bat")
    copyFile("build/makefile", "../csources/makefile")

    setCurrentDir("../csources")
    for kind, path in walkDir("c_code"):
      if kind == pcDir:
        exec("git add " & path / "*.c")
    exec("git commit -am \"updated csources to version " & NimVersion & "\"")
    exec("git push origin master")
    exec("git tag -am \"Version $1\" v$1" % NimVersion)
    exec("git push origin v$1" % NimVersion)
  finally:
    setCurrentDir(cwd)

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
  of "doc", "docs": web("--onlyDocs " & op.cmdLineRest)
  of "json2": web("--json2 " & op.cmdLineRest)
  of "website": website(op.cmdLineRest & " --googleAnalytics:UA-48159761-1")
  of "web0":
    # undocumented command for Araq-the-merciful:
    web(op.cmdLineRest & " --googleAnalytics:UA-48159761-1")
  of "pdf": pdf()
  of "csource", "csources": csource(op.cmdLineRest)
  of "zip": zip(op.cmdLineRest)
  of "xz": xz(op.cmdLineRest)
  of "nsis": nsis(op.cmdLineRest)
  of "geninstall": geninstall(op.cmdLineRest)
  of "distrohelper": geninstall()
  of "install": install(op.cmdLineRest)
  of "testinstall": testUnixInstall()
  of "test", "tests": tests(op.cmdLineRest)
  of "temp": temp(op.cmdLineRest)
  of "winrelease": winRelease()
  of "nimble": buildNimble()
  of "tools": buildTools()
  of "pushcsource", "pushcsources": pushCsources()
  else: showHelp()
of cmdEnd: showHelp()
