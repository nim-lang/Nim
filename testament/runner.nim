# Running of tests and evaluation of success

import algorithm, compiler/nodejs, os, osproc, specs, streams, strutils,
  pegs, types, times

const
  targetToExt*: array[Target, string] = ["c", "cpp", "m", "js"]
  targetToCmd*: array[Target, string] = ["c", "cpp", "objc", "js"]

proc makeDeterministic(s: string): string =
  var x = splitLines(s)
  sort(x, system.cmp)
  result = join(x, "\n")

proc nimcacheDir*(id: string): string =
  ## Give each test a private nimcache dir so they don't clobber each other's.
  var mangled = id
  for i in 0..<mangled.len:
    if mangled[i] notin {'a'..'z', 'A'..'Z', '0'..'9'}:
      mangled[i] = '_'

  return "nimcache" / mangled

proc normalizeMsg(s: string): string =
  result = newStringOfCap(s.len+1)
  for x in splitLines(s):
    if result.len > 0: result.add '\L'
    result.add x.strip

proc getFileDir(filename: string): string =
  result = filename.splitFile().dir
  if not result.isAbsolute():
    result = getCurrentDir() / result

proc setResult(res: var Result, expectedMsg, givenMsg: string, err: ResultEnum) =
  res.expectedMsg = expectedMsg
  res.givenMsg = givenMsg
  res.given.res = err

proc cmpMsgs(res: var Result) =
  proc maybeFailed(expected, given: int): bool =
    expected != 0 and expected != given

  if strip(res.inst.expected.msg) notin strip(res.given.msg):
    setResult(res, res.inst.expected.msg, res.given.msg, reMsgsDiffer)

  elif res.inst.expected.nimout.len > 0 and
      res.inst.expected.nimout.normalizeMsg notin res.given.nimout.normalizeMsg:
    setResult(res, res.inst.expected.nimout, res.given.nimout, reMsgsDiffer)

  elif res.inst.expected.tfile == "" and
      extractFilename(res.inst.expected.file) != extractFilename(res.given.file) and
      "internal error:" notin res.inst.expected.msg:
    setResult(res, res.inst.expected.file, res.given.file, reFilesDiffer)

  elif maybeFailed(res.inst.expected.line, res.given.line) or
      maybeFailed(res.inst.expected.column, res.given.column):
    setResult(res, $res.inst.expected.line & ':' & $res.inst.expected.column,
              $res.given.line & ':' & $res.given.column,
              reLinesDiffer)

  elif res.inst.expected.tfile != "" and
      extractFilename(res.inst.expected.tfile) != extractFilename(res.given.tfile) and
      "internal error:" notin res.inst.expected.msg:
    setResult(res, res.inst.expected.tfile, res.given.tfile, reFilesDiffer)

  elif maybeFailed(res.inst.expected.tline, res.given.tline) or
      maybeFailed(res.inst.expected.tcolumn, res.given.tcolumn):
    setResult(res, $res.inst.expected.tline & ':' & $res.inst.expected.tcolumn,
              $res.given.tline & ':' & $res.given.tcolumn,
              reLinesDiffer)

  else:
    setResult(res, res.inst.expected.msg, res.given.msg, reSuccess)

proc generatedFile(test: Instance): string =
  let (_, name, _) = test.filename.splitFile
  let ext = targetToExt[test.target]
  result = nimcacheDir(test.id) /
    (if test.target == targetJS: "" else: "compiler_") &
    name.changeFileExt(ext)

proc needsCodegenCheck(test: TestData): bool =
  result = test.maxCodeSize > 0 or test.ccodeCheck.len > 0

proc codegenCheck(res: var Result) =
  try:
    let genFile = generatedFile(res.inst)
    let contents = readFile(genFile).string
    let check = res.inst.expected.ccodeCheck
    if check.len > 0:
      if check[0] == '\\':
        # little hack to get 'match' support:
        if not contents.match(check.peg):
          res.given.res = reCodegenFailure
      elif contents.find(check.peg) < 0:
        res.given.res = reCodegenFailure
      res.expectedMsg = check
    if res.inst.expected.maxCodeSize > 0 and contents.len > res.inst.expected.maxCodeSize:
      res.given.res = reCodegenFailure
      res.given.msg = "generated code size: " & $contents.len
      res.expectedMsg = "max allowed size: " & $res.inst.expected.maxCodeSize
  except ValueError:
    res.given.res = reInvalidPeg
    echo getCurrentExceptionMsg()
  except IOError:
    res.given.res = reCodeNotFound
    echo getCurrentExceptionMsg()

proc nimoutCheck(res: var Result) =
  let exp = res.inst.expected.nimout.strip.replace("\C\L", "\L")
  let giv = res.given.nimout.strip.replace("\C\L", "\L")
  if exp notin giv:
    res.given.res = reMsgsDiffer

proc compilerOutputTests(res: var Result) =
  if res.given.res == reSuccess:
    if res.inst.expected.needsCodegenCheck:
      codegenCheck(res)
      res.givenMsg = res.given.msg
    if res.inst.expected.nimout.len > 0:
      res.expectedMsg = res.inst.expected.nimout
      res.givenMsg = res.given.nimout.strip
      nimoutCheck(res)
  else:
    res.givenMsg = res.given.nimout.strip

proc prefixCmdTemplate(cmd: string): string =
  if cmd.len < 4: cmdTemplate()
  elif cmd[0..<3] == "nim": "$prefix" & cmd[3..^1]
  else: cmd

proc callCompiler(inst: Instance, prefix: string, extraOptions: string): TestData =
  let
    pegLineError =
      peg"{[^(]*} '(' {\d+} ', ' {\d+} ') ' ('Error') ':' \s* {.*}"
    pegLineTemplate =
      peg"{[^(]*} '(' {\d+} ', ' {\d+} ') ' 'template/generic instantiation from here'.*"
    pegOtherError = peg"'Error:' \s* {.*}"
    pegSuccess = peg"'Hint: operation successful'.*"
    pegOfInterest = pegLineError / pegOtherError

  let nimcache = nimcacheDir(inst.id)

  let options = inst.options & " " &
    ("--nimCache:" & nimcache).quoteShell & " " & extraOptions

  let c = parseCmdLine(prefixCmdTemplate(inst.cmd) % [
    "prefix", prefix,
    "target", targetToCmd[inst.target],
    "options", options,
    "file", inst.filename.quoteShell,
    "filedir", inst.filename.getFileDir()])

  var p = startProcess(command=c[0], args=c[1.. ^1],
                       options={poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var suc = ""
  var err = ""
  var tmpl = ""
  var x = newStringOfCap(120)
  result.nimout = ""
  while outp.readLine(x.TaintedString) or running(p):
    result.nimout.add(x & "\n")
    if x =~ pegOfInterest:
      # `err` should contain the last error/warning message
      err = x
    elif x =~ pegLineTemplate and err == "":
      # `tmpl` contains the last template expansion before the error
      tmpl = x
    elif x =~ pegSuccess:
      suc = x
  close(p)

  if tmpl =~ pegLineTemplate:
    result.tfile = extractFilename(matches[0])
    result.tline = parseInt(matches[1])
    result.tcolumn = parseInt(matches[2])
  if err =~ pegLineError:
    result.file = extractFilename(matches[0])
    result.line = parseInt(matches[1])
    result.column = parseInt(matches[2])
    result.msg = matches[3]
  elif err =~ pegOtherError:
    result.msg = matches[0]
  elif suc =~ pegSuccess:
    result.res = reSuccess

proc callCCompiler(inst: Instance, prefix: string): TestData =
  let options = inst.options

  let c = parseCmdLine(prefixCmdTemplate(inst.cmd) % [
    "prefix", prefix,
    "target", targetToCmd[inst.target],
    "options", options,
    "file", inst.filename.quoteShell,
    "filedir", inst.filename.getFileDir()])

  var p = startProcess(command="gcc", args=c[5 .. ^1],
                       options={poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var x = newStringOfCap(120)
  while outp.readLine(x.TaintedString) or running(p):
    result.nimout.add(x & "\n")
  close(p)
  if p.peekExitCode == 0:
    result.res = reSuccess

proc callRun(test: Instance, prefix: string, options: string): TestData =
  result = callCompiler(test, prefix, options)

  if result.res != reSuccess:
    return

  let isJsTarget = test.target == targetJS
  var exeFile: string
  if isJsTarget:
    let (_, file, _) = splitFile(test.filename)
    exeFile = nimcacheDir(test.id) / file & ".js"
  else:
    exeFile = changeFileExt(test.filename, ExeExt)

  if not existsFile(exeFile):
    result.msg = "executable not found"
    result.res = reExeNotFound
    return

  let nodejs = if isJsTarget: findNodeJs() else: ""
  if isJsTarget and nodejs == "":
    result.msg = "nodejs binary not in PATH"
    result.res = reExeNotFound
    return

  let exeCmd = (if isJsTarget: nodejs & " " else: "") & exeFile
  try:
    var (buf, exitCode) = execCmdEx(exeCmd, options = {poStdErrToStdOut})

    # Treat all failure codes from nodejs as 1. Older versions of nodejs used
    # to return other codes, but for us it is sufficient to know that it's not 0.
    if exitCode != 0: exitCode = 1

    result.outp = buf.string
    result.exitCode = exitCode
  except:
    result.msg = getCurrentExceptionMsg()
    result.res = reException

proc callRunC(test: Instance, prefix: string, options: string): TestData =
  # runs C code. Doesn't support any specs, just goes by exit code.
  let tname = test.filename.addFileExt(".c")
  let cdata = callCCompiler(test, prefix)
  if cdata.res != reSuccess:
    return cdata

  let exeFile = changeFileExt(test.filename, ExeExt)
  try:
    var (_, exitCode) = execCmdEx(exeFile, options = {poStdErrToStdOut, poUsePath})
    if exitCode != 0: result.res = reExitCodesDiffer
  except:
    result.msg = getCurrentExceptionMsg()
    result.res = reException

proc run*(test: Instance, prefix: string, i, n: int): Result =
  result.inst = test

  result.startTime = epochTime()
  defer:
    result.endTime = epochTime()

  if test.expected.res == reIgnored:
    setResult(result, "", "", reIgnored)
    return

  case test.action
  of actionCompile:
    result.given = callCompiler(test, prefix,
      extraOptions=" --stdout --hint[Path]:off --hint[Processing]:off")

    compilerOutputTests(result)

  of actionRun:
    result.given = callRun(test, prefix, "")

    if result.given.res != reSuccess:
      setResult(result, test.expected.msg, result.given.msg, result.given.res)
      return

    let bufB = if test.sortoutput: makeDeterministic(strip(result.given.outp))
                else: strip(result.given.outp)
    let expectedOut = strip(test.expected.outp)

    if result.given.exitCode != test.expected.exitCode:
      setResult(result, "exitcode: " & $result.inst.expected.exitCode,
                "exitcode: " & $result.given.exitCode & "\n\nOutput:\n" & bufB,
                reExitCodesDiffer)
      return

    if bufB != expectedOut and test.action != actionRunNoSpec:
      if not (test.expected.substr and expectedOut in bufB):
        setResult(result, result.inst.expected.outp, bufB, reOutputsDiffer)
        return

    compilerOutputTests(result)

  of actionRunC:
    result.given = callRunC(test, prefix, "")
    if result.given.res != reSuccess:
      setResult(result, test.expected.msg, result.given.msg, result.given.res)
      return

  of actionReject:
    result.given = callCompiler(test, prefix, "")
    cmpMsgs(result)

  of actionRunNoSpec:
    result.given = callCompiler(test, prefix, "")
    setResult(result, "", result.given.msg, result.given.res)

  of actionExec:
    try:
      let (outp, errC) = execCmdEx(test.options.strip())

      if errC == 0:
        result.given.res = reSuccess
      else:
        result.given.res = reExitCodesDiffer
        result.given.msg = outp.string
    except:
      result.given.msg = getCurrentExceptionMsg()
      result.given.res = reException

    setResult(result, "", result.given.msg, result.given.res)

type
  Item = object
    bundle: Bundle
    prefix: string
    i, n: int
  Res = object
    results: seq[Result]
    i: int

var jobs: Channel[Item]
var results: Channel[Res]

proc run(bundle: Bundle, prefix: string, i, n: int): seq[Result] =
  for test in bundle:
    result.add run(test, prefix, i, n)

proc worker() {.thread.} =
  while true:
    let (ok, item) = jobs.tryRecv()
    if not ok:
      break

    results.send Res(results: run(item.bundle, item.prefix, item.i, item.n), i: item.i)

proc run*(tests: seq[Bundle], prefix: string, report: proc(res: Result)) =
  open(jobs)
  defer: close(jobs)
  open(results)
  defer: close(results)

  # Add all jobs
  for i in 0..<tests.len:
    let test = tests[i]
    jobs.send(Item(bundle: test, prefix: prefix, i:i, n: tests.len))

  var thr: seq[Thread[void]] = @[]

  for i in 0..<countProcessors()+1:
    thr.add Thread[void]()
    createThread(thr[i], worker)

  # Collect results, one by one - order shouldn't really matter but we'll
  # do it in the same order that was given
  for i in 0..<tests.len:
    let res = results.recv()

    for x in res.results: report x

  joinThreads(thr)

  when false:
    # The following implementation base on spawn is broken: results don't get
    # reported until the end of all spawn tasks being done it seems
    proc run(bundle: Bundle, i, n: int): seq[Result] =
      for test in bundle.tests:
        result.add run(test, i, n)

    proc run*(tests: seq[Bundle], report: proc(res: Result)) =
      var responses = newSeq[FlowVar[seq[Result]]](tests.len)

      # Spawn all test runners
      for i in 0..<tests.len:
        let test = tests[i]
        responses[i] = spawn run(test, i, tests.len)

      # Collect results, one by one - order shouldn't really matter but we'll
      # do it in the same order that was given
      for i in 0..<tests.len:
        for result in ^(responses[i]):
          report result
