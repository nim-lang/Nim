#
#
#            Nim Tester
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## HTML generator for the tester.

import cgi, backend, strutils, json, os, tables

import "testamenthtml.templ"

proc generateTestRunTabListItemPartial(outfile: File, testRunRow: JsonNode, firstRow = false) =
  let
    # The first tab gets the bootstrap class for a selected tab
    firstTabActiveClass = if firstRow: "active"
                          else: ""
    testrunid = testRunRow["testrun"].str
    commitId = htmlQuote testRunRow["commit"].str
    hash = htmlQuote(testRunRow["commit"].str)
    branch = htmlQuote(testRunRow["branch"].str)
    machineId = htmlQuote testRunRow["machine"].str
    machineName = htmlQuote(testRunRow["machine"].str)

  outfile.generateHtmlTabListItem(
      firstTabActiveClass,
      testrunid,
      commitId,
      machineId,
      branch,
      hash,
      machineName
    )

proc generateTestResultPanelPartial(outfile: File, testResultRow: JsonNode, onlyFailing = false) =
  let
    trId = htmlQuote(
      testResultRow["testrun"].str &
      "-" &
      testResultRow["category"].str &
      "_" &
      testResultRow["name"].str
      ).multiReplace({".": "_", " ": "_", ":": "_"})
    name = testResultRow["name"].str.htmlQuote()
    category = testResultRow["category"].str.htmlQuote()
    target = testResultRow["target"].str.htmlQuote()
    action = testResultRow["action"].str.htmlQuote()
    result = htmlQuote testResultRow["result"].str
    expected = testResultRow["expected"].str
    gotten = testResultRow["given"].str
    timestamp = htmlQuote testResultRow["timestamp"].str
  var panelCtxClass, textCtxClass, bgCtxClass, resultSign, resultDescription: string
  case result
  of "reSuccess":
    if onlyFailing:
      return
    panelCtxClass = "success"
    textCtxClass = "success"
    bgCtxClass = "success"
    resultSign = "ok"
    resultDescription = "PASS"
  of "reIgnored":
    if onlyFailing:
      return
    panelCtxClass = "info"
    textCtxClass = "info"
    bgCtxClass = "info"
    resultSign = "question"
    resultDescription = "SKIP"
  else:
    panelCtxClass = "danger"
    textCtxClass = "danger"
    bgCtxClass = "danger"
    resultSign = "exclamation"
    resultDescription = "FAIL"

  outfile.generateHtmlTestresultPanelBegin(
    trId, name, target, category, action, resultDescription,
    timestamp,
    result, resultSign,
    panelCtxClass, textCtxClass, bgCtxClass
  )
  if expected.isNilOrWhitespace() and gotten.isNilOrWhitespace():
    outfile.generateHtmlTestresultOutputNone()
  else:
    outfile.generateHtmlTestresultOutputDetails(
      expected.strip().htmlQuote,
      gotten.strip().htmlQuote
    )
  outfile.generateHtmlTestresultPanelEnd()

type
  TestRunAllTests = object
    data: JSonNode
    totalCount, successCount, ignoredCount, failedCount: int
    successPercentage, ignoredPercentage, failedPercentage: BiggestFloat
  AllTests = seq[TestRunAllTests]

proc allTestResults(): AllTests =
  var testRunTable = newOrderedTable[string, TestRunAllTests]()
  for file in os.walkFiles("testresults/*.json"):
    let data = parseFile(file)
    if data.kind != JArray:
      echo "[ERROR] ignoring json file that is not an array: ", file
    else:
      for elem in data:
        let testRunId = elem["testrun"].str
        var
          newTestRun = false
          testRun: TestRunAllTests
        if testRunId notin testRunTable:
          testRun.data = newJArray()
          newTestRun = true
        else:
          testRun = testRunTable[testRunId]
        testRun.data.add elem
        let state = elem["result"].str
        if state.contains("reSuccess"): inc testRun.successCount
        elif state.contains("reIgnored"): inc testRun.ignoredCount
        testRunTable[testRunId] = testRun
  result.newSeq(testRunTable.len())
  var i = testRunTable.len() - 1
  for id, run in testRunTable:
    var resultRun: TestRunAllTests
    resultRun = run
    resultRun.totalCount = resultRun.data.len()
    resultRun.successPercentage = 100 * (resultRun.successCount.toBiggestFloat() / resultRun.totalCount.toBiggestFloat())
    resultRun.ignoredPercentage = 100 * (resultRun.ignoredCount.toBiggestFloat() / resultRun.totalCount.toBiggestFloat())
    resultRun.failedCount = resultRun.totalCount - resultRun.successCount - resultRun.ignoredCount
    resultRun.failedPercentage = 100 * (resultRun.failedCount.toBiggestFloat() / resultRun.totalCount.toBiggestFloat())
    # Reverse order: last in table will be most recent
    result[i] = resultRun
    dec i


proc generateTestResultsPanelGroupPartial(outfile: File, allResults: JsonNode, onlyFailing = false) =
  for testresultRow in allResults:
    generateTestResultPanelPartial(outfile, testresultRow, onlyFailing)

proc generateTestRunTabContentPartial(outfile: File, allResults: TestRunAllTests, testRunRow: JsonNode, onlyFailing = false, firstRow = false) =
  let
    # The first tab gets the bootstrap classes for a selected and displaying tab content
    firstTabActiveClass = if firstRow: " in active"
                          else: ""
    testrunid = testRunRow["testrun"].str
    commitId = htmlQuote testRunRow["commit"].str
    hash = htmlQuote(testRunRow["commit"].str)
    branch = htmlQuote(testRunRow["branch"].str)
    machineId = htmlQuote testRunRow["machine"].str
    machineName = htmlQuote(testRunRow["machine"].str)
    os = htmlQuote(testRunRow["os"].str)
    cpu = htmlQuote(testRunRow["cpu"].str)

  outfile.generateHtmlTabPageBegin(
    firstTabActiveClass, testrunid, commitId,
    machineId, branch, hash, machineName, os, cpu,
    allResults.totalCount,
    allResults.successCount, formatBiggestFloat(allResults.successPercentage, ffDecimal, 2) & "%",
    allResults.ignoredCount, formatBiggestFloat(allResults.ignoredPercentage, ffDecimal, 2) & "%",
    allResults.failedCount, formatBiggestFloat(allResults.failedPercentage, ffDecimal, 2) & "%",
    onlyFailing
  )
  generateTestResultsPanelGroupPartial(outfile, allResults.data, onlyFailing)
  outfile.generateHtmlTabPageEnd()

proc generateTestRunsHtmlPartial(outfile: File, allResults: AllTests, onlyFailing = false) =
  outfile.generateHtmlTabListBegin()
  var first = true
  for testRun in allResults:
    if testRun.data.len > 0:
      generateTestRunTabListItemPartial(outfile, testRun.data[0], first)
      first = false
  outfile.generateHtmlTabListEnd()

  outfile.generateHtmlTabContentsBegin()
  first = true
  for testRun in allResults:
    if testRun.data.len < 1: continue
    generateTestRunTabContentPartial(outfile, testRun, testRun.data[0], onlyFailing, first)
    first = false
  outfile.generateHtmlTabContentsEnd()

proc generateHtml*(filename: string, onlyFailing: bool) =
  var outfile = open(filename, fmWrite)

  outfile.generateHtmlBegin()

  generateTestRunsHtmlPartial(outfile, allTestResults(), onlyFailing)

  outfile.generateHtmlEnd()

  outfile.flushFile()
  close(outfile)
