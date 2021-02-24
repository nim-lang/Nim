#
#
#        The Nim Installation Generator
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, parseopt, parsecfg, strtabs, streams, debcreation,
  std / sha1

const
  maxOS = 20 # max number of OSes
  maxCPU = 20 # max number of CPUs
  buildShFile = "build.sh"
  buildBatFile = "build.bat"
  buildBatFile32 = "build32.bat"
  buildBatFile64 = "build64.bat"
  makeFile = "makefile"
  installShFile = "install.sh"
  deinstallShFile = "deinstall.sh"

type
  AppType = enum appConsole, appGUI
  Action = enum
    actionNone,   # action not yet known
    actionCSource # action: create C sources
    actionInno,   # action: create Inno Setup installer
    actionNsis,   # action: create NSIS installer
    actionScripts # action: create install and deinstall scripts
    actionZip     # action: create zip file
    actionXz,     # action: create xz file
    actionDeb     # action: prepare deb package

  FileCategory = enum
    fcWinBin,     # binaries for Windows
    fcConfig,     # configuration files
    fcData,       # data files
    fcDoc,        # documentation files
    fcLib,        # library files
    fcOther,      # other files; will not be copied on UNIX
    fcWindows,    # files only for Windows
    fcUnix,       # files only for Unix; must be after ``fcWindows``
    fcUnixBin,    # binaries for Unix
    fcDocStart,   # links to documentation for Windows installer
    fcNimble      # nimble package files to copy to /opt/nimble/pkgs/pkg-ver

  ConfigData = object of RootObj
    actions: set[Action]
    cat: array[FileCategory, seq[string]]
    binPaths, authors, oses, cpus, downloads: seq[string]
    cfiles: array[1..maxOS, array[1..maxCPU, seq[string]]]
    platforms: array[1..maxOS, array[1..maxCPU, bool]]
    ccompiler, linker, innosetup, nsisSetup: tuple[path, flags: string]
    name, displayName, version, description, license, infile, outdir: string
    mainfile, libpath: string
    innoSetupFlag, installScript, uninstallScript: bool
    explicitPlatforms: bool
    vars: StringTableRef
    app: AppType
    nimArgs: string
    debOpts: TDebOptions
    nimblePkgName: string

const
  unixDirVars: array[fcConfig..fcLib, string] = [
    "$configdir", "$datadir", "$docdir", "$libdir"
  ]

func iniConfigData(c: var ConfigData) =
  c.actions = {}
  for i in low(FileCategory)..high(FileCategory): c.cat[i] = @[]
  c.binPaths = @[]
  c.authors = @[]
  c.oses = @[]
  c.cpus = @[]
  c.downloads = @[]
  c.ccompiler = ("", "")
  c.linker = ("", "")
  c.innosetup = ("", "")
  c.nsisSetup = ("", "")
  c.name = ""
  c.displayName = ""
  c.version = ""
  c.description = ""
  c.license = ""
  c.infile = ""
  c.mainfile = ""
  c.outdir = ""
  c.nimArgs = ""
  c.libpath = ""
  c.innoSetupFlag = false
  c.installScript = false
  c.uninstallScript = false
  c.vars = newStringTable(modeStyleInsensitive)

  c.debOpts.buildDepends = ""
  c.debOpts.pkgDepends = ""
  c.debOpts.shortDesc = ""
  c.debOpts.licenses = @[]

func firstBinPath(c: ConfigData): string =
  if c.binPaths.len > 0: result = c.binPaths[0]
  else: result = ""

func `\`(a, b: string): string =
  result = if a.len == 0: b else: a & '\\' & b

template toUnix(s: string): string = s.replace('\\', '/')
template toWin(s: string): string = s.replace('/', '\\')

func skipRoot(f: string): string =
  # "abc/def/xyz" --> "def/xyz"
  var i = 0
  result = ""
  for component in split(f, {DirSep, AltSep}):
    if i > 0: result = result / component
    inc i
  if result.len == 0: result = f

include "inno.nimf"
include "nsis.nimf"
include "buildsh.nimf"
include "makefile.nimf"
include "buildbat.nimf"
include "install.nimf"
include "deinstall.nimf"

# ------------------------- configuration file -------------------------------

const
  Version = "1.0"
  Usage = "niminst - Nim Installation Generator Version " & Version & """

  (c) 2015 Andreas Rumpf
Usage:
  niminst [options] command[;command2...] ini-file[.ini] [compile_options]
Command:
  csource             build C source code for source based installations
  scripts             build install and deinstall scripts
  zip                 build the ZIP file
  inno                build the Inno Setup installer
  nsis                build the NSIS Setup installer
  deb                 create files for debhelper
Options:
  -o, --output:dir    set the output directory
  -m, --main:file     set the main nim file, by default ini-file with .nim
                      extension
  --var:name=value    set the value of a variable
  -h, --help          shows this help
  -v, --version       shows the version
Compile_options:
  will be passed to the Nim compiler
"""

proc parseCmdLine(c: var ConfigData) =
  var p = initOptParser()
  while true:
    next(p)
    var kind = p.kind
    var key = p.key
    var val = p.val.string
    case kind
    of cmdArgument:
      if c.actions == {}:
        for a in split(normalize(key.string), {';', ','}):
          case a
          of "csource": incl(c.actions, actionCSource)
          of "scripts": incl(c.actions, actionScripts)
          of "zip": incl(c.actions, actionZip)
          of "xz": incl(c.actions, actionXz)
          of "inno": incl(c.actions, actionInno)
          of "nsis": incl(c.actions, actionNsis)
          of "deb": incl(c.actions, actionDeb)
          else: quit(Usage)
      else:
        c.infile = addFileExt(key.string, "ini")
        c.nimArgs = cmdLineRest(p).string
        break
    of cmdLongOption, cmdShortOption:
      case normalize(key.string)
      of "help", "h":
        stdout.write(Usage)
        quit(0)
      of "version", "v":
        stdout.write(Version & "\n")
        quit(0)
      of "o", "output": c.outdir = val
      of "m", "main": c.mainfile = changeFileExt(val, "nim")
      of "var":
        var idx = val.find('=')
        if idx < 0: quit("invalid command line")
        c.vars[substr(val, 0, idx-1)] = substr(val, idx+1)
      else: quit(Usage)
    of cmdEnd: break
  if c.infile.len == 0: quit(Usage)
  if c.mainfile.len == 0: c.mainfile = changeFileExt(c.infile, "nim")

proc eqT(a, b: string; t: proc (a: char): char{.nimcall.}): bool =
  ## equality under a transformation ``t``. candidate for the stdlib?
  var i = 0
  var j = 0
  while i < a.len and j < b.len:
    let aa = t a[i]
    let bb = t b[j]
    if aa == '\0':
      inc i
      if bb == '\0': inc j
    elif bb == '\0': inc j
    else:
      if aa != bb: return false
      inc i
      inc j
  result = i >= a.len and j >= b.len

func tPath(c: char): char =
  if c == '\\': '/'
  else: c

func ignoreFile(f, explicit: string, allowHtml: bool): bool =
  let (_, name, ext) = splitFile(f)
  let html = if not allowHtml: ".html" else: ""
  result = (ext in ["", ".exe", ".idx", ".o", ".obj", ".dylib"] or
            ext == html or name[0] == '.') and not eqT(f, explicit, tPath)

proc walkDirRecursively(s: var seq[string], root, explicit: string,
                        allowHtml: bool) =
  let tail = splitPath(root).tail
  if tail == "nimcache" or tail[0] == '.':
    return
  let allowHtml = allowHtml or tail == "doc"
  for k, f in walkDir(root):
    if f[0] == '.' and root[0] != '.':
      discard "skip .git directories etc"
    else:
      case k
      of pcFile, pcLinkToFile:
        if not ignoreFile(f, explicit, allowHtml):
          add(s, unixToNativePath(f))
      of pcDir:
        walkDirRecursively(s, f, explicit, allowHtml)
      of pcLinkToDir: discard

proc addFiles(s: var seq[string], patterns: seq[string]) =
  for p in items(patterns):
    if dirExists(p):
      walkDirRecursively(s, p, p, false)
    else:
      var i = 0
      for f in walkPattern(p):
        if dirExists(f):
          walkDirRecursively(s, f, p, false)
        elif not ignoreFile(f, p, false):
          add(s, unixToNativePath(f))
          inc(i)
      if i == 0: echo("[Warning] No file found that matches: " & p)

proc pathFlags(p: var CfgParser, k, v: string,
               t: var tuple[path, flags: string]) =
  case normalize(k)
  of "path": t.path = v
  of "flags": t.flags = v
  else: quit(errorStr(p, "unknown variable: " & k))

proc filesOnly(p: var CfgParser, k, v: string, dest: var seq[string]) =
  case normalize(k)
  of "files": addFiles(dest, split(v, {';'}))
  else: quit(errorStr(p, "unknown variable: " & k))

proc yesno(p: var CfgParser, v: string): bool =
  case normalize(v)
  of "yes", "y", "on", "true":
    result = true
  of "no", "n", "off", "false":
    result = false
  else: quit(errorStr(p, "unknown value; use: yes|no"))

func incl(s: var seq[string], x: string): int =
  for i in 0 ..< s.len:
    if cmpIgnoreStyle(s[i], x) == 0: return i
  s.add(x)
  result = s.len-1

func platforms(c: var ConfigData, v: string) =
  for line in splitLines(v):
    let p = line.find(": ")
    if p <= 1: continue
    let os = line.substr(0, p-1).strip
    let cpus = line.substr(p+1).strip
    c.oses.add(os)
    for cpu in cpus.split(';'):
      let cpuIdx = c.cpus.incl(cpu)
      c.platforms[c.oses.len][cpuIdx+1] = true

proc parseIniFile(c: var ConfigData) =
  var
    p: CfgParser
    section = ""
    hasCpuOs = false
  var input = newFileStream(c.infile, fmRead)
  if input != nil:
    open(p, input, c.infile)
    while true:
      var k = next(p)
      case k.kind
      of cfgEof: break
      of cfgSectionStart:
        section = normalize(k.section)
      of cfgKeyValuePair:
        var v = `%`(k.value, c.vars, {useEnvironment, useEmpty})
        c.vars[k.key] = v

        case section
        of "project":
          case normalize(k.key)
          of "name": c.name = v
          of "displayname": c.displayName = v
          of "version": c.version = v
          of "os":
            c.oses = split(v, {';'})
            hasCpuOs = true
            if c.explicitPlatforms:
              quit(errorStr(p, "you cannot have both 'platforms' and 'os'"))
          of "cpu":
            c.cpus = split(v, {';'})
            hasCpuOs = true
            if c.explicitPlatforms:
              quit(errorStr(p, "you cannot have both 'platforms' and 'cpu'"))
          of "platforms":
            platforms(c, v)
            c.explicitPlatforms = true
            if hasCpuOs:
              quit(errorStr(p, "you cannot have both 'platforms' and 'os'"))
          of "authors": c.authors = split(v, {';'})
          of "description": c.description = v
          of "app":
            case normalize(v)
            of "console": c.app = appConsole
            of "gui": c.app = appGUI
            else: quit(errorStr(p, "expected: console or gui"))
          of "license": c.license = unixToNativePath(k.value)
          else: quit(errorStr(p, "unknown variable: " & k.key))
        of "var": discard
        of "winbin": filesOnly(p, k.key, v, c.cat[fcWinBin])
        of "config": filesOnly(p, k.key, v, c.cat[fcConfig])
        of "data": filesOnly(p, k.key, v, c.cat[fcData])
        of "documentation":
          case normalize(k.key)
          of "files": addFiles(c.cat[fcDoc], split(v, {';'}))
          of "start": addFiles(c.cat[fcDocStart], split(v, {';'}))
          else: quit(errorStr(p, "unknown variable: " & k.key))
        of "lib": filesOnly(p, k.key, v, c.cat[fcLib])
        of "other": filesOnly(p, k.key, v, c.cat[fcOther])
        of "windows":
          case normalize(k.key)
          of "files": addFiles(c.cat[fcWindows], split(v, {';'}))
          of "binpath": c.binPaths = split(v, {';'})
          of "innosetup": c.innoSetupFlag = yesno(p, v)
          of "download": c.downloads.add(v)
          else: quit(errorStr(p, "unknown variable: " & k.key))
        of "unix":
          case normalize(k.key)
          of "files": addFiles(c.cat[fcUnix], split(v, {';'}))
          of "installscript": c.installScript = yesno(p, v)
          of "uninstallscript": c.uninstallScript = yesno(p, v)
          else: quit(errorStr(p, "unknown variable: " & k.key))
        of "unixbin": filesOnly(p, k.key, v, c.cat[fcUnixBin])
        of "innosetup": pathFlags(p, k.key, v, c.innosetup)
        of "nsis": pathFlags(p, k.key, v, c.nsisSetup)
        of "ccompiler": pathFlags(p, k.key, v, c.ccompiler)
        of "linker": pathFlags(p, k.key, v, c.linker)
        of "deb":
          case normalize(k.key)
          of "builddepends":
            c.debOpts.buildDepends = v
          of "packagedepends", "pkgdepends":
            c.debOpts.pkgDepends = v
          of "shortdesc":
            c.debOpts.shortDesc = v
          of "licenses":
            # file,license;file,license;
            var i = 0
            var file = ""
            var license = ""
            var afterComma = false
            while i < v.len():
              case v[i]
              of ',':
                afterComma = true
              of ';':
                if file == "" or license == "":
                  quit(errorStr(p, "Invalid `licenses` key."))
                c.debOpts.licenses.add((file, license))
                afterComma = false
                file = ""
                license = ""
              else:
                if afterComma: license.add(v[i])
                else: file.add(v[i])
              inc(i)
          else: quit(errorStr(p, "unknown variable: " & k.key))
        of "nimble":
          case normalize(k.key)
          of "pkgname":
            c.nimblePkgName = v
          of "pkgfiles":
            addFiles(c.cat[fcNimble], split(v, {';'}))
          else:
            quit(errorStr(p, "invalid key: " & k.key))
        else: quit(errorStr(p, "invalid section: " & section))

      of cfgOption: quit(errorStr(p, "syntax error"))
      of cfgError: quit(errorStr(p, k.msg))
    close(p)
    if c.name.len == 0: c.name = changeFileExt(extractFilename(c.mainfile), "")
    if c.displayName.len == 0: c.displayName = c.name
  else:
    quit("cannot open: " & c.infile)

# ------------------------- generate source based installation ---------------

proc readCFiles(c: var ConfigData, osA, cpuA: int) =
  var p: CfgParser
  var f = splitFile(c.infile).dir / "mapping.txt"
  c.cfiles[osA][cpuA] = @[]
  var input = newFileStream(f, fmRead)
  var section = ""
  if input != nil:
    open(p, input, f)
    while true:
      var k = next(p)
      case k.kind
      of cfgEof: break
      of cfgSectionStart:
        section = normalize(k.section)
      of cfgKeyValuePair:
        case section
        of "ccompiler": pathFlags(p, k.key, k.value, c.ccompiler)
        of "linker":
          pathFlags(p, k.key, k.value, c.linker)
          # HACK: we conditionally add ``-lm -ldl``, so remove them from the
          # linker flags:
          c.linker.flags = c.linker.flags.replaceWord("-lm").replaceWord(
                           "-ldl").replaceWord("-lroot").replaceWord(
                           "-lnetwork").strip
        else:
          if cmpIgnoreStyle(k.key, "libpath") == 0:
            c.libpath = k.value
      of cfgOption:
        if section == "cfiles" and cmpIgnoreStyle(k.key, "file") == 0:
          add(c.cfiles[osA][cpuA], k.value)
      of cfgError: quit(errorStr(p, k.msg))
    close(p)
  else:
    quit("Cannot open: " & f)

func buildDir(os, cpu: int): string =
  "c_code" / ($os & "_" & $cpu)

func getOutputDir(c: var ConfigData): string =
  if c.outdir.len > 0: c.outdir else: "build"

proc writeFile(filename, content, newline: string) =
  var f: File
  if open(f, filename, fmWrite):
    for x in splitLines(content):
      write(f, x)
      write(f, newline)
    close(f)
  else:
    quit("Cannot open for writing: " & filename)

proc deduplicateFiles(c: var ConfigData) =
  var tab = newStringTable()
  let build = getOutputDir(c)
  for osA in countup(1, c.oses.len):
    for cpuA in countup(1, c.cpus.len):
      if c.explicitPlatforms and not c.platforms[osA][cpuA]: continue
      for dup in mitems(c.cfiles[osA][cpuA]):
        let key = $secureHashFile(build / dup)
        let val = buildDir(osA, cpuA) / extractFilename(dup)
        let orig = tab.getOrDefault(key)
        if orig.len > 0:
          # file is identical, so delete duplicate:
          removeFile(dup)
          dup = orig
        else:
          tab[key] = val

proc writeInstallScripts(c: var ConfigData) =
  if c.installScript:
    writeFile(installShFile, generateInstallScript(c), "\10")
    inclFilePermissions(installShFile, {fpUserExec, fpGroupExec, fpOthersExec})
  if c.uninstallScript:
    writeFile(deinstallShFile, generateDeinstallScript(c), "\10")
    inclFilePermissions(deinstallShFile, {fpUserExec, fpGroupExec, fpOthersExec})

template gatherFiles(fun, libpath, outDir) =
  block:
    template copySrc(src) =
      let dst = outDir / extractFilename(src)
      when false: echo (dst, dst)
      fun(src, dst)

    for f in walkFiles(libpath / "lib/*.h"): copySrc(f)
    # commenting out for now, see discussion in https://github.com/nim-lang/Nim/pull/13413
    # copySrc(libpath / "lib/wrappers/linenoise/linenoise.h")

proc srcdist(c: var ConfigData) =
  let cCodeDir = getOutputDir(c) / "c_code"
  if not dirExists(cCodeDir): createDir(cCodeDir)
  gatherFiles(copyFile, c.libpath, cCodeDir)
  var winIndex = -1
  var intel32Index = -1
  var intel64Index = -1
  for osA in 1..c.oses.len:
    let osname = c.oses[osA-1]
    if osname.cmpIgnoreStyle("windows") == 0: winIndex = osA
    for cpuA in 1..c.cpus.len:
      if c.explicitPlatforms and not c.platforms[osA][cpuA]: continue
      let cpuname = c.cpus[cpuA-1]
      if cpuname.cmpIgnoreStyle("i386") == 0: intel32Index = cpuA
      elif cpuname.cmpIgnoreStyle("amd64") == 0: intel64Index = cpuA
      var dir = getOutputDir(c) / buildDir(osA, cpuA)
      if dirExists(dir): removeDir(dir)
      createDir(dir)
      var cmd = ("nim compile -f --symbolfiles:off --compileonly " &
                 "--gen_mapping --cc:gcc --skipUserCfg" &
                 " --os:$# --cpu:$# $# $#") %
                 [osname, cpuname, c.nimArgs, c.mainfile]
      echo(cmd)
      if execShellCmd(cmd) != 0:
        quit("Error: call to nim compiler failed")
      readCFiles(c, osA, cpuA)
      for i in 0 .. c.cfiles[osA][cpuA].len-1:
        let dest = dir / extractFilename(c.cfiles[osA][cpuA][i])
        let relDest = buildDir(osA, cpuA) / extractFilename(c.cfiles[osA][cpuA][i])
        copyFile(dest=dest, source=c.cfiles[osA][cpuA][i])
        c.cfiles[osA][cpuA][i] = relDest
  # second pass: remove duplicate files
  deduplicateFiles(c)
  writeFile(getOutputDir(c) / buildShFile, generateBuildShellScript(c), "\10")
  inclFilePermissions(getOutputDir(c) / buildShFile, {fpUserExec, fpGroupExec, fpOthersExec})
  writeFile(getOutputDir(c) / makeFile, generateMakefile(c), "\10")
  if winIndex >= 0:
    if intel32Index >= 0 or intel64Index >= 0:
      writeFile(getOutputDir(c) / buildBatFile,
                generateBuildBatchScript(c, winIndex, intel32Index, intel64Index), "\13\10")
    if intel32Index >= 0:
      writeFile(getOutputDir(c) / buildBatFile32, "SET ARCH=32\nCALL build.bat\n")
    if intel64Index >= 0:
      writeFile(getOutputDir(c) / buildBatFile64, "SET ARCH=64\nCALL build.bat\n")
  writeInstallScripts(c)

# --------------------- generate inno setup -----------------------------------
proc setupDist(c: var ConfigData) =
  let scrpt = generateInnoSetup(c)
  let n = "build" / "install_$#_$#.iss" % [toLowerAscii(c.name), c.version]
  writeFile(n, scrpt, "\13\10")
  when defined(windows):
    if c.innosetup.path.len == 0:
      c.innosetup.path = "iscc.exe"
    let outcmd = if c.outdir.len == 0: "build" else: c.outdir
    let cmd = "$# $# /O$# $#" % [quoteShell(c.innosetup.path),
                                 c.innosetup.flags, outcmd, n]
    echo(cmd)
    if execShellCmd(cmd) == 0:
      removeFile(n)
    else:
      quit("External program failed")

# --------------------- generate NSIS setup -----------------------------------
proc setupDist2(c: var ConfigData) =
  let scrpt = generateNsisSetup(c)
  let n = "build" / "install_$#_$#.nsi" % [toLowerAscii(c.name), c.version]
  writeFile(n, scrpt, "\13\10")
  when defined(windows):
    if c.nsisSetup.path.len == 0:
      c.nsisSetup.path = "makensis.exe"
    let outcmd = if c.outdir.len == 0: "build" else: c.outdir
    let cmd = "$# $# /O$# $#" % [quoteShell(c.nsisSetup.path),
                                 c.nsisSetup.flags, outcmd, n]
    echo(cmd)
    if execShellCmd(cmd) == 0:
      removeFile(n)
    else:
      quit("External program failed")

proc xzDist(c: var ConfigData; windowsZip=false) =
  let proj = toLowerAscii(c.name) & "-" & c.version
  let tmpDir = if c.outdir.len == 0: "build" else: c.outdir

  proc processFile(destFile, src: string) =
    let dest = tmpDir / destFile
    when false: echo "Copying ", src, " to ", dest
    if not fileExists(src):
      echo "[Warning] Source file doesn't exist: ", src
    let destDir = dest.splitFile.dir
    if not dirExists(destDir): createDir(destDir)
    copyFileWithPermissions(src, dest)

  if not windowsZip and not fileExists("build" / buildBatFile):
    quit("No C sources found in ./build/, please build by running " &
         "./koch csource -d:danger.")

  if not windowsZip:
    processFile(proj / buildBatFile, "build" / buildBatFile)
    processFile(proj / buildBatFile32, "build" / buildBatFile32)
    processFile(proj / buildBatFile64, "build" / buildBatFile64)
    processFile(proj / buildShFile, "build" / buildShFile)
    processFile(proj / makeFile, "build" / makeFile)
    processFile(proj / installShFile, installShFile)
    processFile(proj / deinstallShFile, deinstallShFile)
    template processFileAux(src, dst) = processFile(dst, src)
    gatherFiles(processFileAux, c.libpath, proj / "c_code")
    for osA in 1..c.oses.len:
      for cpuA in 1..c.cpus.len:
        var dir = buildDir(osA, cpuA)
        for k, f in walkDir("build" / dir):
          if k == pcFile: processFile(proj / dir / extractFilename(f), f)
  else:
    for f in items(c.cat[fcWinBin]):
      let filename = f.extractFilename
      processFile(proj / "bin" / filename, f)

  let osSpecific = if windowsZip: fcWindows else: fcUnix
  for cat in items({fcConfig..fcOther, osSpecific, fcNimble}):
    echo("Current category: ", cat)
    for f in items(c.cat[cat]): processFile(proj / f, f)

  # Copy the .nimble file over
  let nimbleFile = c.nimblePkgName & ".nimble"
  processFile(proj / nimbleFile, nimbleFile)

  when true:
    let oldDir = getCurrentDir()
    setCurrentDir(tmpDir)
    try:
      if windowsZip:
        if execShellCmd("7z a -tzip $1.zip $1" % proj) != 0:
          echo("External program failed (zip)")
        when false:
          writeFile("config.txt", """;!@Install@!UTF-8!
Title="Nim v$1"
BeginPrompt="Do you want to configure Nim v$1?"
RunProgram="tools\downloader.exe"
;!@InstallEnd@!""" % NimVersion)
          if execShellCmd("7z a -sfx7zS2.sfx -t7z $1.exe $1" % proj) != 0:
            echo("External program failed (7z)")
      else:
        if execShellCmd("gtar cf $1.tar --exclude=.DS_Store $1" %
                        proj) != 0:
          # try old 'tar' without --exclude feature:
          if execShellCmd("tar cf $1.tar $1" % proj) != 0:
            echo("External program failed")

        if execShellCmd("xz -9f $1.tar" % proj) != 0:
          echo("External program failed")
    finally:
      setCurrentDir(oldDir)

# -- prepare build files for .deb creation

proc debDist(c: var ConfigData) =
  if not fileExists(getOutputDir(c) / "build.sh"): quit("No build.sh found.")
  if not fileExists(getOutputDir(c) / "install.sh"): quit("No install.sh found.")

  if c.debOpts.shortDesc == "": quit("shortDesc must be set in the .ini file.")
  if c.debOpts.licenses.len == 0:
    echo("[Warning] No licenses specified for .deb creation.")

  # -- Copy files into /tmp/..
  echo("Copying source to tmp/niminst/deb/")
  var currentSource = getCurrentDir()
  var workingDir = getTempDir() / "niminst" / "deb"
  var upstreamSource = (c.name.toLowerAscii() & "-" & c.version)

  createDir(workingDir / upstreamSource)

  template copyNimDist(f, dest: string) =
    createDir((workingDir / upstreamSource / dest).splitFile.dir)
    copyFile(currentSource / f, workingDir / upstreamSource / dest)

  # Don't copy all files, only the ones specified in the config:
  copyNimDist(buildShFile, buildShFile)
  copyNimDist(makeFile, makeFile)
  copyNimDist(installShFile, installShFile)
  createDir(workingDir / upstreamSource / "build")
  gatherFiles(copyNimDist, c.libpath, "build")
  for osA in 1..c.oses.len:
    for cpuA in 1..c.cpus.len:
      var dir = buildDir(osA, cpuA)
      for k, f in walkDir(dir):
        if k == pcFile: copyNimDist(f, dir / extractFilename(f))
  for cat in items({fcConfig..fcOther, fcUnix}):
    for f in items(c.cat[cat]): copyNimDist(f, f)

  # -- Create necessary build files for debhelper.

  let mtnName = c.vars["mtnname"]
  let mtnEmail = c.vars["mtnemail"]

  prepDeb(c.name, c.version, mtnName, mtnEmail, c.debOpts.shortDesc,
          c.description, c.debOpts.licenses, c.cat[fcUnixBin], c.cat[fcConfig],
          c.cat[fcDoc], c.cat[fcLib], c.debOpts.buildDepends,
          c.debOpts.pkgDepends)

# ------------------- main ----------------------------------------------------

proc main() =
  var c: ConfigData
  iniConfigData(c)
  parseCmdLine(c)
  parseIniFile(c)
  if actionInno in c.actions:
    setupDist(c)
  if actionNsis in c.actions:
    setupDist2(c)
  if actionCSource in c.actions:
    srcdist(c)
  if actionScripts in c.actions:
    writeInstallScripts(c)
  if actionZip in c.actions:
    xzDist(c, true)
  if actionXz in c.actions:
    xzDist(c)
  if actionDeb in c.actions:
    debDist(c)

when isMainModule:
  main()
