## Part of 'koch' responsible for the documentation generation.

import os, strutils, osproc

const
  gaCode* = " --doc.googleAnalytics:UA-48159761-1"

  nimArgs = "--hint[Conf]:off --hint[Path]:off --hint[Processing]:off -d:boot --putenv:nimversion=$#" % system.NimVersion
  gitUrl = "https://github.com/nim-lang/Nim"
  docHtmlOutput = "doc/html"
  webUploadOutput = "web/upload"
  docHackDir = "tools/dochack"

proc exe*(f: string): string =
  result = addFileExt(f, ExeExt)
  when defined(windows):
    result = result.replace('/','\\')

proc findNim*(): string =
  var nim = "nim".exe
  result = "bin" / nim
  if existsFile(result): return
  for dir in split(getEnv("PATH"), PathSep):
    if existsFile(dir / nim): return dir / nim
  # assume there is a symlink to the exe or something:
  return nim

proc exec*(cmd: string, errorcode: int = QuitFailure, additionalPath = "") =
  let prevPath = getEnv("PATH")
  if additionalPath.len > 0:
    var absolute = additionalPATH
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
    let CleanPath = r"$1\system32;$1;$1\System32\Wbem" % getEnv"SYSTEMROOT"
  else:
    const CleanPath = r"/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"
  putEnv("PATH", CleanPath & PathSep & additionalPath)
  echo(cmd)
  if execShellCmd(cmd) != 0: quit("FAILURE", errorcode)
  putEnv("PATH", prevPath)

proc nimexec*(cmd: string) =
  # Consider using `nimCompile` instead
  exec findNim() & " " & cmd

proc nimCompile*(input: string, outputDir = "bin", mode = "c", options = "") =
  let output = outputDir / input.splitFile.name.exe
  let cmd = findNim() & " " & mode & " -o:" & output & " " & options & " " & input
  exec cmd

proc nimCompileFold*(desc, input: string, outputDir = "bin", mode = "c", options = "") =
  let output = outputDir / input.splitFile.name.exe
  let cmd = findNim() & " " & mode & " -o:" & output & " " & options & " " & input
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
doc/tut1.rst
doc/tut2.rst
doc/tut3.rst
doc/nimc.rst
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

  doc = """
lib/system.nim
lib/system/io.nim
lib/system/nimscript.nim
lib/deprecated/pure/ospaths.nim
lib/pure/parsejson.nim
lib/pure/cstrutils.nim
lib/core/macros.nim
lib/pure/marshal.nim
lib/core/typeinfo.nim
lib/impure/re.nim
lib/pure/typetraits.nim
nimsuggest/sexp.nim
lib/pure/concurrency/threadpool.nim
lib/pure/concurrency/cpuinfo.nim
lib/pure/concurrency/cpuload.nim
lib/js/dom.nim
lib/js/jsffi.nim
lib/js/jsconsole.nim
lib/js/asyncjs.nim
lib/pure/os.nim
lib/pure/strutils.nim
lib/pure/math.nim
lib/std/editdistance.nim
lib/std/wordwrap.nim
lib/experimental/diff.nim
lib/pure/algorithm.nim
lib/pure/stats.nim
lib/windows/winlean.nim
lib/pure/random.nim
lib/pure/complex.nim
lib/pure/times.nim
lib/pure/osproc.nim
lib/pure/pegs.nim
lib/pure/dynlib.nim
lib/pure/strscans.nim
lib/pure/parseopt.nim
lib/pure/hashes.nim
lib/pure/strtabs.nim
lib/pure/lexbase.nim
lib/pure/parsecfg.nim
lib/pure/parsexml.nim
lib/pure/parsecsv.nim
lib/pure/parsesql.nim
lib/pure/streams.nim
lib/pure/terminal.nim
lib/pure/cgi.nim
lib/pure/unicode.nim
lib/pure/strmisc.nim
lib/pure/htmlgen.nim
lib/pure/parseutils.nim
lib/pure/browsers.nim
lib/impure/db_postgres.nim
lib/impure/db_mysql.nim
lib/impure/db_sqlite.nim
lib/impure/db_odbc.nim
lib/pure/db_common.nim
lib/pure/httpclient.nim
lib/pure/smtp.nim
lib/pure/ropes.nim
lib/pure/unidecode/unidecode.nim
lib/pure/xmlparser.nim
lib/pure/htmlparser.nim
lib/pure/xmltree.nim
lib/pure/colors.nim
lib/pure/mimetypes.nim
lib/pure/json.nim
lib/pure/base64.nim
lib/impure/nre.nim
lib/impure/nre/private/util.nim
lib/pure/collections/tables.nim
lib/pure/collections/sets.nim
lib/pure/collections/lists.nim
lib/pure/collections/sharedlist.nim
lib/pure/collections/sharedtables.nim
lib/pure/collections/intsets.nim
lib/pure/collections/deques.nim
lib/pure/encodings.nim
lib/pure/collections/sequtils.nim
lib/pure/collections/rtarrays.nim
lib/pure/cookies.nim
lib/pure/memfiles.nim
lib/pure/collections/critbits.nim
lib/core/locks.nim
lib/core/rlocks.nim
lib/pure/oids.nim
lib/pure/endians.nim
lib/pure/uri.nim
lib/pure/nimprof.nim
lib/pure/unittest.nim
lib/packages/docutils/highlite.nim
lib/packages/docutils/rst.nim
lib/packages/docutils/rstast.nim
lib/packages/docutils/rstgen.nim
lib/pure/logging.nim
lib/pure/options.nim
lib/pure/asyncdispatch.nim
lib/pure/asyncnet.nim
lib/pure/asyncstreams.nim
lib/pure/asyncfutures.nim
lib/pure/nativesockets.nim
lib/pure/asynchttpserver.nim
lib/pure/net.nim
lib/pure/selectors.nim
lib/pure/sugar.nim
lib/pure/collections/chains.nim
lib/pure/asyncfile.nim
lib/pure/asyncftpclient.nim
lib/pure/lenientops.nim
lib/pure/md5.nim
lib/pure/rationals.nim
lib/pure/distros.nim
lib/pure/oswalkdir.nim
lib/pure/collections/heapqueue.nim
lib/pure/fenv.nim
lib/std/sha1.nim
lib/std/varints.nim
lib/std/time_t.nim
lib/impure/rdstdin.nim
lib/wrappers/linenoise/linenoise.nim
lib/pure/strformat.nim
lib/pure/segfaults.nim
lib/pure/mersenne.nim
lib/pure/coro.nim
lib/pure/httpcore.nim
lib/pure/bitops.nim
lib/pure/nimtracker.nim
lib/pure/punycode.nim
lib/pure/volatile.nim
lib/posix/posix_utils.nim
""".splitWhitespace()

  doc0 = """
lib/system/threads.nim
lib/system/channels.nim
""".splitWhitespace()

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
lib/wrappers/odbcsql.nim
lib/js/jscore.nim
""".splitWhitespace()

proc sexec(cmds: openarray[string]) =
  ## Serial queue wrapper around exec.
  for cmd in cmds:
    echo(cmd)
    let (outp, exitCode) = osproc.execCmdEx(cmd)
    if exitCode != 0: quit outp

proc mexec(cmds: openarray[string]) =
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
  exec(findNim() & " doc $# -o:$# $#" %
    [nimArgs, destPath / "docgen_sample.html", "doc" / "docgen_sample.nim"])

proc buildDoc(nimArgs, destPath: string) =
  # call nim for the documentation:
  var
    commands = newSeq[string](rst2html.len + len(doc0) + len(doc) + withoutIndex.len)
    i = 0
  let nim = findNim()
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
    commands[i] = nim & " doc $# --git.url:$# -o:$# --index:on $#" %
      [nimArgs, gitUrl,
      destPath / changeFileExt(splitFile(d).name, "html"), d]
    i.inc
  for d in items(withoutIndex):
    commands[i] = nim & " doc2 $# --git.url:$# -o:$# $#" %
      [nimArgs, gitUrl,
      destPath / changeFileExt(splitFile(d).name, "html"), d]
    i.inc

  mexec(commands)
  exec(nim & " buildIndex -o:$1/theindex.html $1" % [destPath])

proc buildPdfDoc*(nimArgs, destPath: string) =
  createDir(destPath)
  if os.execShellCmd("pdflatex -version") != 0:
    echo "pdflatex not found; no PDF documentation generated"
  else:
    const pdflatexcmd = "pdflatex -interaction=nonstopmode "
    for d in items(pdf):
      exec(findNim() & " rst2tex $# $#" % [nimArgs, d])
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

proc buildJS() =
  exec(findNim() & " js -d:release --out:$1 tools/nimblepkglist.nim" %
      [webUploadOutput / "nimblepkglist.js"])
  exec(findNim() & " js " & (docHackDir / "dochack.nim"))

proc buildDocs*(args: string) =
  let
    a = nimArgs & " " & args
    docHackJs = "dochack.js"
    docHackJsSource = docHackDir / docHackJs
    docHackJsDest = docHtmlOutput / docHackJs
  buildJS()                     # This call generates docHackJsSource
  let docup = webUploadOutput / NimVersion
  createDir(docup)
  buildDocSamples(a, docup)
  buildDoc(a, docup)

  # 'nimArgs' instead of 'a' is correct here because we don't want
  # that the offline docs contain the 'gaCode'!
  createDir(docHtmlOutput)
  buildDocSamples(nimArgs, docHtmlOutput)
  buildDoc(nimArgs, docHtmlOutput)
  copyFile(docHackJsSource, docHackJsDest)
  copyFile(docHackJsSource, docup / docHackJs)
