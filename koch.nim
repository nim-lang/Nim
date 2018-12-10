#
#
#         Maintenance program for Nim
#        (c) Copyright 2017 Andreas Rumpf
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
  {.link: "icons/koch-amd64-windows-vcc.res".}
when defined(i386) and defined(windows) and defined(vcc):
  {.link: "icons/koch-i386-windows-vcc.res".}

import
  os, strutils, parseopt, osproc, streams

import tools / kochdocs

const VersionAsString = system.NimVersion

const
  HelpText = """
+-----------------------------------------------------------------+
|         Maintenance program for Nim                             |
|             Version $1|
|             (c) 2017 Andreas Rumpf                              |
+-----------------------------------------------------------------+
Build time: $2, $3

Usage:
  koch [options] command [options for command]
Options:
  --help, -h               shows this help and quits
  --latest                 bundle the installers with a bleeding edge Nimble
  --stable                 bundle the installers with a stable Nimble
Possible Commands:
  boot [options]           bootstraps with given command line options
  distrohelper [bindir]    helper for distro packagers
  tools                    builds Nim related tools
  nimble                   builds the Nimble tool
Boot options:
  -d:release               produce a release version of the compiler
  -d:useLinenoise          use the linenoise library for interactive mode
                           (not needed on Windows)
  -d:leanCompiler          produce a compiler without JS codegen or
                           documentation generator in order to use less RAM
                           for bootstrapping

Commands for core developers:
  docs [options]           generates the full documentation
  csource -d:release       builds the C sources for installation
  pdf                      builds the PDF documentation
  zip                      builds the installation zip package
  xz                       builds the installation tar.xz package
  testinstall              test tar.xz package; Unix only!
  tests [options]          run the testsuite (run a subset of tests by
                           specifying a category, e.g. `tests cat async`)
  temp options             creates a temporary compiler for testing
  pushcsource              push generated C sources to its repo
Web options:
  --googleAnalytics:UA-... add the given google analytics code to the docs. To
                           build the official docs, use UA-48159761-1
"""

template withDir(dir, body) =
  let old = getCurrentDir()
  try:
    setCurrentDir(dir)
    body
  finally:
    setCurrentdir(old)

let nimHome        = quoteShell(getAppDir()) # may contain spaces
let installerIni   = nimHome / "compiler" / "installer.ini"
let nimMain        = nimHome / "compiler" / "nim.nim"
let compileNimInst = nimHome / "tools" / "niminst" / "niminst"

proc tryExec(cmd: string): bool =
  echo(cmd)
  result = execShellCmd(cmd) == 0

proc safeRemove(filename: string) =
  if existsFile(filename): removeFile(filename)

proc overwriteFile(source, dest: string) =
  safeRemove(dest)
  moveFile(source, dest)

proc copyExe(source, dest: string) =
  safeRemove(dest)
  copyFile(dest=dest, source=source)
  inclFilePermissions(dest, {fpUserExec})

proc csource(args: string) =
  nimexec(("cc $1 -r $3 --var:version=$2 --var:mingw=none csource " &
           "--main:$4 $5 $1") %
       [args, VersionAsString, compileNimInst, nimMain, installerIni])

proc bundleNimbleSrc(latest: bool) =
  ## bunldeNimbleSrc() bundles a specific Nimble commit with the tarball. We
  ## always bundle the latest official release.
  withDir(nimHome):
    if not dirExists("dist/nimble/.git"):
      exec("git clone https://github.com/nim-lang/nimble.git dist/nimble")
    if not latest:
      withDir("dist/nimble"):
        exec("git checkout -f stable")
        exec("git pull")

proc bundleNimbleExe(latest: bool) =
  bundleNimbleSrc(latest)
  # installer.ini expects it under $nim/bin
  nimCompile(nimHome / "dist/nimble/src/nimble.nim", options = "-d:release --nilseqs:on")

proc buildNimfind() =
  nimCompile(nimHome / "tools/nimfind.nim", options = "-d:release")

proc buildNimble(latest: bool) =
  # old installations created nim/nimblepkg/*.nim files. We remove these
  # here so that it cannot cause problems (nimble bug #306):
  withDir(nimHome):
    if dirExists("bin/nimblepkg"):
      removeDir("bin/nimblepkg")
    # if koch is used for a tar.xz, build the dist/nimble we shipped
    # with the tarball:
    var installDir = "dist/nimble"
    if not latest and dirExists(installDir) and not dirExists("dist/nimble/.git"):
      discard "don't do the git dance"
    else:
      if not dirExists("dist/nimble/.git"):
        if dirExists(installDir):
          var id = 0
          while dirExists("dist/nimble" & $id):
            inc id
          installDir = "dist/nimble" & $id
        exec("git clone https://github.com/nim-lang/nimble.git " & installDir)
      withDir(installDir):
        if latest:
          exec("git checkout -f master")
        else:
          exec("git checkout -f stable")
        exec("git pull")
    nimCompile(installDir / "src/nimble.nim", options = "--noNimblePath --nilseqs:on -d:release")

proc bundleNimsuggest() =
  nimCompile(nimHome / "nimsuggest" / "nimsuggest.nim", options = "-d:release")

proc buildVccTool() =
  nimCompile(nimHome / "tools/vccenv/vccexe.nim")

proc bundleWinTools() =
  # TODO: consider building under `bin` instead of `.`
  withDir(nimHome):
    nimCompile("tools/finish.nim", outputDir = "")

    buildVccTool()
    nimCompile("tools/nimgrab.nim", options = "-d:ssl")
    nimCompile("tools/nimgrep.nim")
    when false:
      # not yet a tool worth including
      nimCompile(r"tools\downloader.nim", options = r"--cc:vcc --app:gui -d:ssl --noNimblePath --path:..\ui")

proc zip(latest: bool; args: string) =
  bundleNimbleExe(latest)
  bundleNimsuggest()
  bundleWinTools()
  nimexec("cc -r $2 --var:version=$1 --var:mingw=none --main:$3 scripts $4" %
       [VersionAsString, compileNimInst, nimMain, installerIni])
  exec("$1 --var:version=$2 --var:mingw=none --main:$3 zip $4" %
       [compileNimInst.exe, VersionAsString, nimMain, installerIni])

proc ensureCleanGit() =
  withDir(nimHome):
   let (outp, status) = osproc.execCmdEx("git diff")
   if outp.len != 0:
     quit "Not a clean git repository; 'git diff' not empty!"
   if status != 0:
     quit "Not a clean git repository; 'git diff' returned non-zero!"

proc xz(latest: bool; args: string) =
  ensureCleanGit()
  bundleNimbleSrc(latest)
  when false:
    bundleNimsuggest()

  nimexec("cc -r $1 --var:version=$2 --var:mingw=none --main:$3 scripts $4" %
         [compileNimInst, VersionAsString, nimMain, installerIni])
  exec("$1 --var:version=$2 --var:mingw=none --main:$3 xz $4" %
         [compileNimInst.exe, VersionAsString, nimMain, installerIni])

proc buildTool(toolname, args: string) =
  nimexec("cc $# $#" % [args, toolname])
  copyFile(dest=nimHome / "bin" / splitFile(toolname).name.exe, source=toolname.exe)

proc buildTools(latest: bool) =
  bundleNimsuggest()
  nimCompile(nimHome / "tools" / "nimgrep.nim", options = "-d:release")
  when defined(windows): buildVccTool()
  nimCompile(nimHome / "nimpretty" / "nimpretty.nim", options = "-d:release")
  buildNimble(latest)
  buildNimfind()

proc nsis(latest: bool; args: string) =
  bundleNimbleExe(latest)
  bundleNimsuggest()
  bundleWinTools()
  # make sure we have generated the niminst executables:
  buildTool(compileNimInst, args)
  #buildTool("tools/nimgrep", args)
  # produce 'nim_debug.exe':
  #exec "nim c compiler" / "nim.nim"
  #copyExe("compiler/nim".exe, "bin/nim_debug".exe)
  exec(("$1 --var:version=$2 --var:mingw=mingw$3" &
        " nsis $4") % [compileNimInst, VersionAsString, $(sizeof(pointer)*8), installerIni])

proc geninstall(args="") =
  nimexec("cc -r $1 --var:version=$2 --var:mingw=none --main:$3 scripts $4 $5" %
       [compileNimInst, VersionAsString, nimMain, installerIni, args])

proc install(args: string) =
  geninstall()
  withDir(nimHome):
    exec("sh ./install.sh $#" % args)

when false:
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
  let nim = "nim".exe
  if existsFile(nimHome / "bin" / nim):
    return nimHome / "bin" / nim

  for dir in split(getEnv("PATH"), PathSep):
    if existsFile(dir / nim):
      return dir / nim

  withDir(nimHome):
    when defined(Posix):
      const buildScript = "build.sh"
      if existsFile(buildScript):
        if tryExec("./" & buildScript):
          return "bin" / nim
    else:
      const buildScript = "build.bat"
      if existsFile(buildScript):
        if tryExec(buildScript):
          return "bin" / nim

  echo("Found no nim compiler and every attempt to build one failed!")
  quit("FAILURE")

proc thVersion(i: int): string =
  result = (nimHome / "compiler" / "nim" & $i).exe

proc boot(args: string) =
  var output = nimHome / "compiler" / "nim".exe
  var finalDest = nimHome / "bin" / "nim".exe
  # default to use the 'c' command:
  let defaultCommand =
    if getEnv("NIM_COMPILE_TO_CPP", "false") == "true": "cpp" else: "c"
  let bootOptions =
    if args.len == 0 or args.startsWith("-"): defaultCommand else: ""

  let smartNimcache =
    if "release" in args:
       nimHome / "nimcache/r_" & hostOs & "_" & hostCpu
    else:
       nimHome / "nimcache/d_" & hostOs & "_" & hostCpu

  copyExe(findStartNim(), 0.thVersion)
  for i in 0..2:
    echo "iteration: ", i+1
    exec i.thVersion & " $# $# --nimcache:$# $#" % [
      bootOptions,
      args,
      smartNimcache,
      nimMain
    ]
    if sameFileContent(output, i.thVersion):
      copyExe(output, finalDest)
      echo "executables are equal: SUCCESS!"
      return
    copyExe(output, (i+1).thVersion)
  copyExe(output, finalDest)
  when not defined(windows):
    echo "[Warning] executables are still not equal"

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
  withDir(nimHome):
    removePattern("web/*.html")
    removePattern("doc/*.html")
    cleanAux(getCurrentDir())
    for kind, path in walkDir(getCurrentDir() / "build"):
      if kind == pcDir:
        echo "removing dir: ", path
        removeDir(path)

# -------------- builds a release ---------------------------------------------

proc winReleaseArch(arch: string) =
  doAssert arch in ["32", "64"]
  let cpu = if arch == "32": "i386" else: "amd64"

  template withMingw(path, body) =
    let prevPath = getEnv("PATH")
    putEnv("PATH", (if path.len > 0: path & PathSep else: "") & prevPath)
    try:
      body
    finally:
      putEnv("PATH", prevPath)

  withMingw r"..\mingw" & arch & r"\bin":
    # Rebuilding koch is necessary because it uses its pointer size to
    # determine which mingw link to put in the NSIS installer.
    nimexec "c --cpu:$# koch" % cpu
    exec "koch boot -d:release --cpu:$#" % cpu
    exec "koch --latest zip -d:release"
    overwriteFile r"build\nim-$#.zip" % VersionAsString,
             r"web\upload\download\nim-$#_x$#.zip" % [VersionAsString, arch]

proc winRelease*() =
  # Now used from "tools/winrelease" and not directly supported by koch
  # anymore!
  # Build -docs file:
  when true:
    buildDocs(gaCode)
    withDir "web/upload/" & VersionAsString:
      exec "7z a -tzip docs-$#.zip *.html" % VersionAsString
    overwriteFile "web/upload/$1/docs-$1.zip" % VersionAsString,
                  "web/upload/download/docs-$1.zip" % VersionAsString
  when true:
    csource("-d:release")
  when sizeof(pointer) == 4:
    winReleaseArch "32"
  when sizeof(pointer) == 8:
    winReleaseArch "64"

# -------------- tests --------------------------------------------------------

template `|`(a, b): string = (if a.len > 0: a else: b)

proc tests(args: string) =
  # we compile the tester with taintMode:on to have a basic
  # taint mode test :-)
  nimexec "cc --taintMode:on --opt:speed " & nimHome / "testament" / "tester.nim"
  # Since tests take a long time (on my machine), and we want to defy
  # Murhpys law - lets make sure the compiler really is freshly
  # compiled!

  let libDir = nimHome / "lib"
  nimexec "c --lib:$1 -d:release --opt:speed $2" % [libDir, nimMain]
  let tester = nimHome / "testament" / "tester".exe
  withDir(nimHome):
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

  var output = nimHome / "compiler" / "nim".exe
  var finalDest = nimHome / "bin" / "nim_temp".exe
  # 125 is the magic number to tell git bisect to skip the current
  # commit.
  let (bootArgs, programArgs) = splitArgs(args)
  let nimexec = findNim()
  exec(nimexec & " c -d:debug --debugger:native " & bootArgs & " " & nimMain, 125)
  copyExe(output, finalDest)
  if programArgs.len > 0:
    exec(finalDest & " " & programArgs)

proc xtemp(cmd: string) =
  copyExe(nimHome / "bin" / "nim".exe, nimHome / "bin" / "nim_backup".exe)
  try:
    temp("")
    copyExe(nimHome / "bin" / "nim_temp".exe, nimHome / "bin" / "nim".exe)
    exec(cmd)
  finally:
    copyExe(nimHome / "bin" / "nim_backup".exe, nimHome / "bin" / "nim".exe)

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

proc testUnixInstall(cmdLineRest: string) =
  csource("-d:release " & cmdLineRest)
  xz(false, cmdLineRest)
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
      execCleanPath("./koch docs", destDir / "bin")
      # check nimble builds:
      execCleanPath("./koch --latest tools")
      # check the tests work:
      putEnv("NIM_EXE_NOT_IN_PATH", "NOT_IN_PATH")
      execCleanPath("./koch tests", destDir / "bin")
      #execCleanPath("./koch tests cat newconfig", destDir / "bin")
    else:
      echo "Version check: failure"
  finally:
    setCurrentDir oldCurrentDir

proc valgrind(cmd: string) =
  # somewhat hacky: '=' sign means "pass to valgrind" else "pass to Nim"
  let args = parseCmdLine(cmd)
  var nimcmd = ""
  var valcmd = ""
  for i, a in args:
    if i == args.len-1:
      # last element is the filename:
      valcmd.add ' '
      valcmd.add changeFileExt(a, ExeExt)
      nimcmd.add ' '
      nimcmd.add a
    elif '=' in a:
      valcmd.add ' '
      valcmd.add a
    else:
      nimcmd.add ' '
      nimcmd.add a
  exec("nim c" & nimcmd)
  let supp = getAppDir() / "tools" / "nimgrind.supp"
  exec("valgrind --suppressions=" & supp & valcmd)

proc showHelp() =
  quit(HelpText % [VersionAsString & spaces(44-len(VersionAsString)),
                   CompileDate, CompileTime], QuitSuccess)

when isMainModule:
  var op = initOptParser()
  var latest = false
  var stable = false
  while true:
    op.next()
    case op.kind
    of cmdLongOption, cmdShortOption:
      case normalize(op.key)
      of "latest": latest = true
      of "stable": stable = true
      else: showHelp()
    of cmdArgument:
      case normalize(op.key)
      of "boot": boot(op.cmdLineRest)
      of "clean": clean(op.cmdLineRest)
      of "doc", "docs": buildDocs(op.cmdLineRest)
      of "doc0", "docs0":
        # undocumented command for Araq-the-merciful:
        buildDocs(op.cmdLineRest & gaCode)
      of "pdf": buildPdfDoc(op.cmdLineRest, "doc/pdf")
      of "csource", "csources": csource(op.cmdLineRest)
      of "zip": zip(latest, op.cmdLineRest)
      of "xz": xz(latest, op.cmdLineRest)
      of "nsis": nsis(latest, op.cmdLineRest)
      of "geninstall": geninstall(op.cmdLineRest)
      of "distrohelper": geninstall()
      of "install": install(op.cmdLineRest)
      of "testinstall": testUnixInstall(op.cmdLineRest)
      of "test", "tests": tests(op.cmdLineRest)
      of "temp": temp(op.cmdLineRest)
      of "xtemp": xtemp(op.cmdLineRest)
      of "wintools": bundleWinTools()
      of "nimble":
        if stable: buildNimble(false)
        else: buildNimble(existsDir(".git") or latest)
      of "nimsuggest": bundleNimsuggest()
      of "tools":
        if stable: buildTools(false)
        else: buildTools(existsDir(".git") or latest)
      of "pushcsource", "pushcsources": pushCsources()
      of "valgrind": valgrind(op.cmdLineRest)
      else: showHelp()
      break
    of cmdEnd: break
