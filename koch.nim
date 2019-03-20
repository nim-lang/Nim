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
  toolsNoNimble            builds Nim related tools (except nimble)
                           doesn't require network connectivity
  nimble                   builds the Nimble tool
Boot options:
  -d:release               produce a release version of the compiler
  -d:useLinenoise          use the linenoise library for interactive mode
                           (not needed on Windows)
  -d:leanCompiler          produce a compiler without JS codegen or
                           documentation generator in order to use less RAM
                           for bootstrapping

Commands for core developers:
  runCI                    runs continuous integration (CI), eg from travis
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

let kochExe* = when isMainModule: os.getAppFilename() # always correct when koch is main program, even if `koch` exe renamed eg: `nim c -o:koch_debug koch.nim`
               else: getAppDir() / "koch".exe # works for winrelease

proc kochExec*(cmd: string) =
  exec kochExe.quoteShell & " " & cmd

proc kochExecFold*(desc, cmd: string) =
  execFold(desc, kochExe.quoteShell & " " & cmd)

template withDir(dir, body) =
  let old = getCurrentDir()
  try:
    setCurrentDir(dir)
    body
  finally:
    setCurrentDir(old)

let origDir = getCurrentDir()
setCurrentDir(getAppDir())

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

const
  compileNimInst = "tools/niminst/niminst"

proc csource(args: string) =
  nimexec(("cc $1 -r $3 --var:version=$2 --var:mingw=none csource " &
           "--main:compiler/nim.nim compiler/installer.ini $1") %
       [args, VersionAsString, compileNimInst])

proc bundleNimbleSrc(latest: bool) =
  ## bunldeNimbleSrc() bundles a specific Nimble commit with the tarball. We
  ## always bundle the latest official release.
  if not dirExists("dist/nimble/.git"):
    exec("git clone https://github.com/nim-lang/nimble.git dist/nimble")
  if not latest:
    withDir("dist/nimble"):
      exec("git checkout -f stable")
      exec("git pull")

proc bundleC2nim() =
  if not dirExists("dist/c2nim/.git"):
    exec("git clone https://github.com/nim-lang/c2nim.git dist/c2nim")
  nimCompile("dist/c2nim/c2nim", options = "--noNimblePath --path:.")

proc bundleNimbleExe(latest: bool) =
  bundleNimbleSrc(latest)
  # installer.ini expects it under $nim/bin
  nimCompile("dist/nimble/src/nimble.nim", options = "-d:release --nilseqs:on")

proc buildNimble(latest: bool) =
  # old installations created nim/nimblepkg/*.nim files. We remove these
  # here so that it cannot cause problems (nimble bug #306):
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
  nimCompile("nimsuggest/nimsuggest.nim", options = "-d:release")

proc buildVccTool() =
  nimCompileFold("Compile Vcc", "tools/vccexe/vccexe.nim")

proc bundleWinTools() =
  # TODO: consider building under `bin` instead of `.`
  nimCompile("tools/finish.nim", outputDir = "")

  buildVccTool()
  nimCompile("tools/nimgrab.nim", options = "-d:ssl")
  nimCompile("tools/nimgrep.nim")
  bundleC2nim()
  when false:
    # not yet a tool worth including
    nimCompile(r"tools\downloader.nim", options = r"--cc:vcc --app:gui -d:ssl --noNimblePath --path:..\ui")

proc zip(latest: bool; args: string) =
  bundleNimbleExe(latest)
  bundleNimsuggest()
  bundleWinTools()
  nimexec("cc -r $2 --var:version=$1 --var:mingw=none --main:compiler/nim.nim scripts compiler/installer.ini" %
       [VersionAsString, compileNimInst])
  exec("$# --var:version=$# --var:mingw=none --main:compiler/nim.nim zip compiler/installer.ini" %
       ["tools/niminst/niminst".exe, VersionAsString])

proc ensureCleanGit() =
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
  nimexec("cc -r $2 --var:version=$1 --var:mingw=none --main:compiler/nim.nim scripts compiler/installer.ini" %
       [VersionAsString, compileNimInst])
  exec("$# --var:version=$# --var:mingw=none --main:compiler/nim.nim xz compiler/installer.ini" %
       ["tools" / "niminst" / "niminst".exe, VersionAsString])

proc buildTool(toolname, args: string) =
  nimexec("cc $# $#" % [args, toolname])
  copyFile(dest="bin" / splitFile(toolname).name.exe, source=toolname.exe)

proc buildTools() =
  bundleNimsuggest()
  nimCompileFold("Compile nimgrep", "tools/nimgrep.nim", options = "-d:release")
  when defined(windows): buildVccTool()
  nimCompileFold("Compile nimpretty", "nimpretty/nimpretty.nim", options = "-d:release")
  nimCompileFold("Compile nimfind", "tools/nimfind.nim", options = "-d:release")

proc nsis(latest: bool; args: string) =
  bundleNimbleExe(latest)
  bundleNimsuggest()
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
  let useCpp = getEnv("NIM_COMPILE_TO_CPP", "false") == "true"
  let smartNimcache = (if "release" in args: "nimcache/r_" else: "nimcache/d_") &
                      hostOs & "_" & hostCpu

  let nimStart = findStartNim()
  for i in 0..2:
    let defaultCommand = if useCpp: "cpp" else: "c"
    let bootOptions = if args.len == 0 or args.startsWith("-"): defaultCommand else: ""
    echo "iteration: ", i+1
    var extraOption = ""
    var nimi = i.thVersion
    if i == 0:
      nimi = nimStart
      extraOption.add " --skipUserCfg --skipParentCfg"
        # The configs are skipped for bootstrap
        # (1st iteration) to prevent newer flags from breaking bootstrap phase.
      let ret = execCmdEx(nimStart & " --version")
      doAssert ret.exitCode == 0
      let version = ret.output.splitLines[0]
      if version.startsWith "Nim Compiler Version 0.19.0":
        extraOption.add " -d:nimBoostrapCsources0_19_0"
        # remove this when csources get updated

    exec "$# $# $# $# --nimcache:$# compiler" / "nim.nim" %
      [nimi, bootOptions, extraOption, args, smartNimcache]
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
    inFold "winrelease koch":
      nimexec "c --cpu:$# koch" % cpu
    kochExecFold("winrelease boot", "boot -d:release --cpu:$#" % cpu)
    kochExecFold("winrelease zip", "--latest zip -d:release")
    overwriteFile r"build\nim-$#.zip" % VersionAsString,
             r"web\upload\download\nim-$#_x$#.zip" % [VersionAsString, arch]

proc winRelease*() =
  # Now used from "tools/winrelease" and not directly supported by koch
  # anymore!
  # Build -docs file:
  when true:
    inFold "winrelease buildDocs":
      buildDocs(gaCode)
    withDir "web/upload/" & VersionAsString:
      inFold "winrelease zipdocs":
        exec "7z a -tzip docs-$#.zip *.html" % VersionAsString
    overwriteFile "web/upload/$1/docs-$1.zip" % VersionAsString,
                  "web/upload/download/docs-$1.zip" % VersionAsString
  when true:
    inFold "winrelease csource":
      csource("-d:release")
  when sizeof(pointer) == 4:
    winReleaseArch "32"
  when sizeof(pointer) == 8:
    winReleaseArch "64"

# -------------- tests --------------------------------------------------------

template `|`(a, b): string = (if a.len > 0: a else: b)

proc tests(args: string) =
  nimexec "cc --opt:speed testament/tester"
  let tester = quoteShell(getCurrentDir() / "testament/tester".exe)
  let success = tryExec tester & " " & (args|"all")
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

  let d = getAppDir()
  var output = d / "compiler" / "nim".exe
  var finalDest = d / "bin" / "nim_temp".exe
  # 125 is the magic number to tell git bisect to skip the current
  # commit.
  let (bootArgs, programArgs) = splitArgs(args)
  let nimexec = findNim()
  exec(nimexec & " c -d:debug --debugger:native " & bootArgs & " " & (d / "compiler" / "nim"), 125)
  copyExe(output, finalDest)
  setCurrentDir(origDir)
  if programArgs.len > 0: exec(finalDest & " " & programArgs)

proc xtemp(cmd: string) =
  let d = getAppDir()
  copyExe(d / "bin" / "nim".exe, d / "bin" / "nim_backup".exe)
  try:
    withDir(d):
      temp""
    copyExe(d / "bin" / "nim_temp".exe, d / "bin" / "nim".exe)
    exec(cmd)
  finally:
    copyExe(d / "bin" / "nim_backup".exe, d / "bin" / "nim".exe)

proc runCI(cmd: string) =
  doAssert cmd.len == 0, cmd # avoid silently ignoring
  echo "runCI:", cmd
  # note(@araq): Do not replace these commands with direct calls (eg boot())
  # as that would weaken our testing efforts.
  when defined(posix): # appveyor (on windows) didn't run this
    kochExecFold("Boot", "boot")
  # boot without -d:nimHasLibFFI to make sure this still works
  kochExecFold("Boot in release mode", "boot -d:release")

  ## build nimble early on to enable remainder to depend on it if needed
  kochExecFold("Build Nimble", "nimble")

  when false:
    execFold("nimble install -y libffi", "nimble install -y libffi")
    kochExecFold("boot -d:release -d:nimHasLibFFI", "boot -d:release -d:nimHasLibFFI")

  if getEnv("NIM_TEST_PACKAGES", "false") == "true":
    execFold("Test selected Nimble packages", "nim c -r testament/tester cat nimble-packages")
  else:
    buildTools() # altenatively, kochExec "tools --toolsNoNimble"

    ## run tests
    execFold("Test nimscript", "nim e tests/test_nimscript.nims")
    when defined(windows):
      # note: will be over-written below
      execFold("Compile tester", "nim c -d:nimCoroutines --os:genode -d:posix --compileOnly testament/tester")

    # main bottleneck here
    execFold("Run tester", "nim c -r -d:nimCoroutines testament/tester --pedantic all -d:nimCoroutines")

    execFold("Run nimdoc tests", "nim c -r nimdoc/tester")
    execFold("Run nimpretty tests", "nim c -r nimpretty/tester.nim")
    when defined(posix):
      execFold("Run nimsuggest tests", "nim c -r nimsuggest/tester")

    ## remaining actions
    when defined(posix):
      kochExecFold("Docs", "docs --git.commit:devel")
      kochExecFold("C sources", "csource")
    elif defined(windows):
      when false:
        kochExec "csource"
        kochExec "zip"

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
      execCleanPath("./koch tests --nim:./bin/nim cat megatest", destDir / "bin")
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
  template isLatest(): bool =
    if stable: false
    else:
      existsDir(".git") or latest
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
      of "runci": runCI(op.cmdLineRest)
      of "test", "tests": tests(op.cmdLineRest)
      of "temp": temp(op.cmdLineRest)
      of "xtemp": xtemp(op.cmdLineRest)
      of "wintools": bundleWinTools()
      of "nimble": buildNimble(isLatest())
      of "nimsuggest": bundleNimsuggest()
      of "toolsnonimble":
        buildTools()
      of "tools":
        buildTools()
        buildNimble(isLatest())
      of "pushcsource", "pushcsources": pushCsources()
      of "valgrind": valgrind(op.cmdLineRest)
      of "c2nim": bundleC2nim()
      else: showHelp()
      break
    of cmdEnd: break
