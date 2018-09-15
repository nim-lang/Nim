import browsers, backend, categories, htmlgen, math, parseopt, os, osproc,
  runner, sequtils, specs, strutils, terminal, types

const
  resultsFile = "testresults.html"
  #jsonFile = "testresults.json" # not used
  Usage = """Usage:
  tester [options] command [arguments]

Command:
  all                         run all tests
  c|cat|category <category>   run all the tests of a certain category
  r|run <test>                run single test file
  html                        generate $1 from the database
Arguments:
  arguments are passed to the compiler
Options:
  --print                   also print results to the console
  --failing                 only show failing/ignored tests
  --targets:"c c++ js objc" run tests for specified targets (default: all)
  --nim:path                use a particular nim executable (default: compiler/nim)
""" % resultsFile

proc addResult(res: Result, passed, skipped, failed, total: int) =
  let inst = res.inst
  let expected = inst.expected
  let name = inst.id & res.inst.options
  let duration = res.endTime - res.startTime
  let durationStr = duration.formatFloat(ffDecimal, precision = 8)
  backend.writeTestResult(id = inst.id,
                          name = name,
                          category = inst.cat.string,
                          target = $inst.target,
                          action = $inst.action,
                          result = $res.given.res,
                          expected = res.expectedMsg,
                          given = res.givenMsg)
  # r.data.addf("$#\t$#\t$#\t$#", name, expected, given, $success)
  let counts = " (" & durationStr & " secs, " & $passed & "/" & $skipped & "/" &
    $failed & "/" & $total & ")"
  case res.given.res
  of reSuccess:
    styledEcho fgGreen, "PASS: ", fgCyan, alignLeft(name, 60), fgBlue, counts
  of reIgnored:
    styledEcho styleDim, fgYellow, "SKIP: ", styleBright, fgCyan,
      alignLeft(name, 60), fgBlue, counts
  else:
    styledEcho styleBright, fgRed, "FAIL: ", fgCyan, name
    styledEcho styleBright, fgCyan, res.inst.id
    styledEcho styleBright, fgRed, "Failure: ", $res.given.res
    styledEcho fgYellow, "Expected:"
    styledEcho styleBright, res.expectedMsg, "\n"
    styledEcho fgYellow, "Gotten:"
    styledEcho styleBright, res.givenMsg, "\n"

  if existsEnv("APPVEYOR"):
    let (outcome, msg) =
      case res.given.res
      of reSuccess:
        ("Passed", "")
      of reIgnored:
        ("Skipped", "")
      else:
        ("Failed", "Failure: " & $res.given.res &
          "\nExpected:\n" & res.expectedMsg & "\n\n" &
          "Gotten:\n" & res.givenMsg)
    var p = startProcess("appveyor", args=["AddTest", res.inst.id.replace("\\", "/") & res.inst.options,
                         "-Framework", "nim-testament", "-FileName",
                         res.inst.cat.string,
                         "-Outcome", outcome, "-ErrorMessage", msg,
                         "-Duration", $(duration*1000).int],
                         options={poStdErrToStdOut, poUsePath, poParentStreams})
    discard waitForExit(p)
    close(p)

when isMainModule:
  os.putenv "NIMTEST_COLOR", "never"
  os.putenv "NIMTEST_OUTPUT_LVL", "PRINT_FAILURES"

  backend.open()
  var optPrintResults = false
  var optFailing = false

  var targetsStr = ""

  var generators = newSeq[Generator]()
  var filters = newSeq[RunFilter]()
  var prefix = "compiler" / "nim"

  var p = initOptParser()
  p.next()
  while p.kind == cmdLongoption:
    case p.key.string.normalize
    of "print", "verbose": optPrintResults = true
    of "failing": optFailing = true
    of "pedantic": discard "now always enabled"
    of "targets":
      targetsStr = p.val.string
      filters.add targetFilter(parseTargets(targetsStr))
    of "nim": prefix = p.val.string
    else: quit Usage
    p.next()
  if p.kind != cmdArgument: quit Usage
  var action = p.key.string.normalize
  p.next()
  # var r = initResults()
  case action
  of "all":
    let options = p.cmdLineRest.string
    generators.add(proc(): auto = allGen(options))

  of "c", "cat", "category":
    var cat = Category(p.key)
    p.next
    let options = p.cmdLineRest.string
    generators.add(proc(): auto = categoryGen(cat, options))

  of "r", "run":
    let testName = p.key.string
    filters.add(proc(run: Instance): bool = testName in run.id)

    var d = splitPath(testName)
    while d[0] != "tests": d = splitPath(d[0])

    let options = p.cmdLineRest.string
    generators.add(proc(): auto = categoryGen(d[1].Category, options))
  of "html":
    generateHtml(resultsFile, optFailing)
    if optPrintResults:
      openDefaultBrowser(resultsFile)
    quit 0
  else:
    quit Usage

  var tests = newSeq[Bundle]()
  for g in generators:
    tests.add filter(g(), proc(x: auto): auto =
      for f in filters:
        if not any(x, f): return false
      return true
    )

  let total = sum(map(tests) do (x: auto) -> int: x.len)

  var passed, skipped, failed: int
  var data: string


  run(tests, prefix, proc (r: Result) =
    case r.given.res
    of reSuccess: passed += 1
    of reIgnored: skipped += 1
    else: failed += 1
    addResult(r, passed, skipped, failed, total)
    data.addf("$#\t$#\t$#\t$#\n", r.inst.id, r.expectedMsg, r.givenMsg, $r.given.res)
    )

  if optPrintResults:
    echo data

  backend.close()

  if failed != 0:
    echo "FAILURE! total: ", total, " passed: ", passed, " skipped: ",
      skipped, " failed: ", failed
    quit(QuitFailure)

if paramCount() == 0:
  quit Usage
