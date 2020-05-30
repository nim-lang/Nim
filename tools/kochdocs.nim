## Part of 'koch' responsible for the documentation generation.

import os, strutils, osproc, sets, pathnorm
import "../compiler/nimpaths"

const
  gaCode* = " --doc.googleAnalytics:UA-48159761-1"
  nimArgs = "--hint:Conf:off --hint:Path:off --hint:Processing:off -d:boot --putenv:nimversion=$#" % system.NimVersion
  gitUrl = "https://github.com/nim-lang/Nim"
  docHtmlOutput = "doc/html"
  webUploadOutput = "web/upload"

var nimExe*: string

proc exe*(f: string): string =
  result = addFileExt(f, ExeExt)
  when defined(windows):
    result = result.replace('/','\\')

proc findNimImpl*(): tuple[path: string, ok: bool] =
  if nimExe.len > 0: return (nimExe, true)
  let nim = "nim".exe
  result.path = "bin" / nim
  result.ok = true
  if existsFile(result.path): return
  for dir in split(getEnv("PATH"), PathSep):
    result.path = dir / nim
    if existsFile(result.path): return
  # assume there is a symlink to the exe or something:
  return (nim, false)

proc findNim*(): string = findNimImpl().path

proc exec*(cmd: string, errorcode: int = QuitFailure, additionalPath = "") =
  let prevPath = getEnv("PATH")
  if additionalPath.len > 0:
    var absolute = additionalPath
    if not absolute.isAbsolute:
      absolute = getCurrentDir() / absolute
    echo("Adding to $PATH: ", absolute)
    putEnv("PATH", (if prevPath.len > 0: prevPath & PathSep else: "") & absolute)
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE", errorcode)
  putEnv("PATH", prevPath)

template inFold*(desc, body) =
  if existsEnv("TRAVIS"):
    echo "travis_fold:start:" & desc.replace(" ", "_")

  body

  if existsEnv("TRAVIS"):
    echo "travis_fold:end:" & desc.replace(" ", "_")

proc execFold*(desc, cmd: string, errorcode: int = QuitFailure, additionalPath = "") =
  ## Execute shell command. Add log folding on Travis CI.
  # https://github.com/travis-ci/travis-ci/issues/2285#issuecomment-42724719
  inFold(desc):
    exec(cmd, errorcode, additionalPath)

proc execCleanPath*(cmd: string,
                   additionalPath = ""; errorcode: int = QuitFailure) =
  # simulate a poor man's virtual environment
  let prevPath = getEnv("PATH")
  when defined(windows):
    let cleanPath = r"$1\system32;$1;$1\System32\Wbem" % getEnv"SYSTEMROOT"
  else:
    const cleanPath = r"/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"
  putEnv("PATH", cleanPath & PathSep & additionalPath)
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE", errorcode)
  putEnv("PATH", prevPath)

proc nimexec*(cmd: string) =
  # Consider using `nimCompile` instead
  exec findNim().quoteShell() & " " & cmd

proc nimCompile*(input: string, outputDir = "bin", mode = "c", options = "") =
  let output = outputDir / input.splitFile.name.exe
  let cmd = findNim().quoteShell() & " " & mode & " -o:" & output & " " & options & " " & input
  exec cmd

proc nimCompileFold*(desc, input: string, outputDir = "bin", mode = "c", options = "") =
  let output = outputDir / input.splitFile.name.exe
  let cmd = findNim().quoteShell() & " " & mode & " -o:" & output & " " & options & " " & input
  execFold(desc, cmd)

const
  pdf = """
doc/manual.rst
doc/lib.rst
doc/tut1.rst
doc/tut2.rst
doc/tut3.rst
doc/nimc.rst
doc/niminst.rst
doc/gc.rst
""".splitWhitespace()

  rst2html = """
doc/intern.rst
doc/apis.rst
doc/lib.rst
doc/manual.rst
doc/manual_experimental.rst
doc/destructors.rst
doc/tut1.rst
doc/tut2.rst
doc/tut3.rst
doc/nimc.rst
doc/hcr.rst
doc/drnim.rst
doc/overview.rst
doc/filters.rst
doc/tools.rst
doc/niminst.rst
doc/nimgrep.rst
doc/gc.rst
doc/estp.rst
doc/idetools.rst
doc/docgen.rst
doc/koch.rst
doc/backends.rst
doc/nimsuggest.rst
doc/nep1.rst
doc/nims.rst
doc/contributing.rst
doc/codeowners.rst
doc/packaging.rst
doc/manual/var_t_return.rst
""".splitWhitespace()

  doc0 = """
lib/system/threads.nim
lib/system/channels.nim
""".splitWhitespace() # ran by `nim doc0` instead of `nim doc`

  withoutIndex = """
lib/wrappers/mysql.nim
lib/wrappers/iup.nim
lib/wrappers/sqlite3.nim
lib/wrappers/postgres.nim
lib/wrappers/tinyc.nim
lib/wrappers/odbcsql.nim
lib/wrappers/pcre.nim
lib/wrappers/openssl.nim
lib/posix/posix.nim
lib/posix/linux.nim
lib/posix/termios.nim
lib/js/jscore.nim
""".splitWhitespace()

  # some of these are include files so shouldn't be docgen'd
  ignoredModules = """
lib/prelude.nim
lib/pure/future.nim
lib/pure/collections/hashcommon.nim
lib/pure/collections/tableimpl.nim
lib/pure/collections/setimpl.nim
lib/pure/ioselects/ioselectors_kqueue.nim
lib/pure/ioselects/ioselectors_select.nim
lib/pure/ioselects/ioselectors_poll.nim
lib/pure/ioselects/ioselectors_epoll.nim
lib/posix/posix_macos_amd64.nim
lib/posix/posix_other.nim
lib/posix/posix_nintendoswitch.nim
lib/posix/posix_nintendoswitch_consts.nim
lib/posix/posix_linux_amd64.nim
lib/posix/posix_linux_amd64_consts.nim
lib/posix/posix_other_consts.nim
lib/posix/posix_openbsd_amd64.nim
lib/posix/posix_haiku.nim
""".splitWhitespace()

when (NimMajor, NimMinor) < (1, 1) or not declared(isRelativeTo):
  proc isRelativeTo(path, base: string): bool =
    let path = path.normalizedPath
    let base = base.normalizedPath
    let ret = relativePath(path, base)
    result = path.len > 0 and not ret.startsWith ".."

proc getDocList(): seq[string] =
  var docIgnore: HashSet[string]
  for a in doc0: docIgnore.incl a
  for a in withoutIndex: docIgnore.incl a
  for a in ignoredModules: docIgnore.incl a

  # don't ignore these even though in lib/system
  const goodSystem = """
lib/system/io.nim
lib/system/nimscript.nim
lib/system/assertions.nim
lib/system/iterators.nim
lib/system/dollars.nim
lib/system/widestrs.nim
""".splitWhitespace()

  for a in walkDirRec("lib"):
    if a.splitFile.ext != ".nim" or
       a.isRelativeTo("lib/pure/includes") or
       a.isRelativeTo("lib/genode") or
       a.isRelativeTo("lib/deprecated") or
       (a.isRelativeTo("lib/system") and a.replace('\\', '/') notin goodSystem) or
       a.replace('\\', '/') in docIgnore:
         continue
    result.add a
  result.add normalizePath("nimsuggest/sexp.nim")

let doc = getDocList()

proc sexec(cmds: openArray[string]) =
  ## Serial queue wrapper around exec.
  for cmd in cmds:
    echo(cmd)
    let (outp, exitCode) = osproc.execCmdEx(cmd)
    if exitCode != 0: quit outp

proc mexec(cmds: openArray[string]) =
  ## Multiprocessor version of exec
  let r = execProcesses(cmds, {poStdErrToStdOut, poParentStreams, poEchoCmd})
  if r != 0:
    echo "external program failed, retrying serial work queue for logs!"
    sexec(cmds)

proc buildDocSamples(nimArgs, destPath: string) =
  ## Special case documentation sample proc.
  ##
  ## TODO: consider integrating into the existing generic documentation builders
  ## now that we have a single `doc` command.
  exec(findNim().quoteShell() & " doc $# -o:$# $#" %
    [nimArgs, destPath / "docgen_sample.html", "doc" / "docgen_sample.nim"])

proc buildDocPackages(nimArgs, destPath: string) =
  # compiler docs, and later, other packages (perhaps tools, testament etc)
  let nim = findNim().quoteShell()
  let extra = "-u:boot"
    # to avoid broken links to manual from compiler dir, but a multi-package
    # structure could be supported later
  exec("$1 doc --project --outdir:$2/compiler $3 --git.url:$4 $5 compiler/nim.nim" %
    [nim, destPath, nimArgs, gitUrl, extra])

proc buildDoc(nimArgs, destPath: string) =
  # call nim for the documentation:
  var
    commands = newSeq[string](rst2html.len + len(doc0) + len(doc) + withoutIndex.len)
    i = 0
  let nim = findNim().quoteShell()
  for d in items(rst2html):
    commands[i] = nim & " rst2html $# --git.url:$# -o:$# --index:on $#" %
      [nimArgs, gitUrl,
      destPath / changeFileExt(splitFile(d).name, "html"), d]
    i.inc
  for d in items(doc0):
    commands[i] = nim & " doc0 $# --git.url:$# -o:$# --index:on $#" %
      [nimArgs, gitUrl,
      destPath / changeFileExt(splitFile(d).name, "html"), d]
    i.inc
  for d in items(doc):
    var nimArgs2 = nimArgs
    if d.isRelativeTo("compiler"): doAssert false
    commands[i] = nim & " doc $# --git.url:$# --outdir:$# --index:on $#" %
      [nimArgs2, gitUrl, destPath, d]
    i.inc
  for d in items(withoutIndex):
    commands[i] = nim & " doc2 $# --git.url:$# -o:$# $#" %
      [nimArgs, gitUrl,
      destPath / changeFileExt(splitFile(d).name, "html"), d]
    i.inc

  mexec(commands)
  exec(nim & " buildIndex -o:$1/theindex.html $1" % [destPath])
    # caveat: this works so long it's called before `buildDocPackages` which
    # populates `compiler/` with unrelated idx files that shouldn't be in index,
    # so should work in CI but you may need to remove your generated html files
    # locally after calling `./koch docs`. The clean fix would be for `idx` files
    # to be transient with `--project` (eg all in memory).

proc buildPdfDoc*(nimArgs, destPath: string) =
  createDir(destPath)
  if os.execShellCmd("pdflatex -version") != 0:
    echo "pdflatex not found; no PDF documentation generated"
  else:
    const pdflatexcmd = "pdflatex -interaction=nonstopmode "
    for d in items(pdf):
      exec(findNim().quoteShell() & " rst2tex $# $#" % [nimArgs, d])
      let tex = splitFile(d).name & ".tex"
      removeFile("doc" / tex)
      moveFile(tex, "doc" / tex)
      # call LaTeX twice to get cross references right:
      exec(pdflatexcmd & changeFileExt(d, "tex"))
      exec(pdflatexcmd & changeFileExt(d, "tex"))
      # delete all the crappy temporary files:
      let pdf = splitFile(d).name & ".pdf"
      let dest = destPath / pdf
      removeFile(dest)
      moveFile(dest=dest, source=pdf)
      removeFile(changeFileExt(pdf, "aux"))
      if existsFile(changeFileExt(pdf, "toc")):
        removeFile(changeFileExt(pdf, "toc"))
      removeFile(changeFileExt(pdf, "log"))
      removeFile(changeFileExt(pdf, "out"))
      removeFile(changeFileExt(d, "tex"))

proc buildJS(): string =
  let nim = findNim()
  exec(nim.quoteShell() & " js -d:release --out:$1 tools/nimblepkglist.nim" %
      [webUploadOutput / "nimblepkglist.js"])
  result = getDocHacksJs(nimr = getCurrentDir(), nim)

proc buildDocs*(args: string) =
  let docHackJsSource = buildJS()
  template fn(args, dir) =
    let dir2 = dir
    let args2 = args
    createDir(dir2)
    buildDocSamples(args2, dir2)
    buildDoc(args2, dir2)
    buildDocPackages(args2, dir2)
    copyFile(docHackJsSource, dir2 / docHackJsSource.lastPathPart)

  fn(nimArgs & " " & args, webUploadOutput / NimVersion)
  fn(nimArgs, docHtmlOutput) # no `args` to avoid offline docs containing the 'gaCode'!
