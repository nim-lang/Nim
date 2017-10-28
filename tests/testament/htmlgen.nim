#
#
#            Nim Tester
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## HTML generator for the tester.

import cgi, backend, strutils, json, os

import "testamenthtml.templ"

proc generateTestRunTabListItemPartial(outfile: File, testRunRow: JsonNode, firstRow = false) =
  let
    # The first tab gets the bootstrap class for a selected tab
    firstTabActiveClass = if firstRow: "active"
                          else: ""
    commitId = htmlQuote testRunRow["commit"].str
    hash = htmlQuote(testRunRow["commit"].str)
    branch = htmlQuote(testRunRow["branch"].str)
    machineId = htmlQuote testRunRow["machine"].str
    machineName = htmlQuote(testRunRow["machine"].str)

  outfile.generateHtmlTabListItem(
      firstTabActiveClass,
      commitId,
      machineId,
      branch,
      hash,
      machineName
    )

proc generateTestResultPanelPartial(outfile: File, testResultRow: JsonNode, onlyFailing = false) =
  let
    trId = htmlQuote(testResultRow["category"].str & "_" & testResultRow["name"].str)
    name = testResultRow["name"].str.htmlQuote()
    category = testResultRow["category"].str.htmlQuote()
    target = testResultRow["target"].str.htmlQuote()
    action = testResultRow["action"].str.htmlQuote()
    result = htmlQuote testResultRow["result"].str
    expected = htmlQuote testResultRow["expected"].str
    gotten = htmlQuote testResultRow["given"].str
    timestamp = "unknown"
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
  AllTests = object
    data: JSonNode
    totalCount, successCount, ignoredCount, failedCount: int
    successPercentage, ignoredPercentage, failedPercentage: BiggestFloat

proc allTestResults(): AllTests =
  result.data = newJArray()
  for file in os.walkFiles("testresults/*.json"):
    let data = parseFile(file)
    if data.kind != JArray:
      echo "[ERROR] ignoring json file that is not an array: ", file
    else:
      for elem in data:
        result.data.add elem
        let state = elem["result"].str
        if state.contains("reSuccess"): inc result.successCount
        elif state.contains("reIgnored"): inc result.ignoredCount

  result.totalCount = result.data.len
  result.successPercentage = 100 * (result.successCount.toBiggestFloat() / result.totalCount.toBiggestFloat())
  result.ignoredPercentage = 100 * (result.ignoredCount.toBiggestFloat() / result.totalCount.toBiggestFloat())
  result.failedCount = result.totalCount - result.successCount - result.ignoredCount
  result.failedPercentage = 100 * (result.failedCount.toBiggestFloat() / result.totalCount.toBiggestFloat())


proc generateTestResultsPanelGroupPartial(outfile: File, allResults: JsonNode, onlyFailing = false) =
  for testresultRow in allResults:
    generateTestResultPanelPartial(outfile, testresultRow, onlyFailing)

proc generateTestRunTabContentPartial(outfile: File, allResults: AllTests, testRunRow: JsonNode, onlyFailing = false, firstRow = false) =
  let
    # The first tab gets the bootstrap classes for a selected and displaying tab content
    firstTabActiveClass = if firstRow: " in active"
                          else: ""
    commitId = htmlQuote testRunRow["commit"].str
    hash = htmlQuote(testRunRow["commit"].str)
    branch = htmlQuote(testRunRow["branch"].str)
    machineId = htmlQuote testRunRow["machine"].str
    machineName = htmlQuote(testRunRow["machine"].str)
    os = htmlQuote("unknown_os")
    cpu = htmlQuote("unknown_cpu")

  outfile.generateHtmlTabPageBegin(
    firstTabActiveClass, commitId,
    machineId, branch, hash, machineName, os, cpu,
    allResults.totalCount,
    allResults.successCount, formatBiggestFloat(allResults.successPercentage, ffDecimal, 2) & "%",
    allResults.ignoredCount, formatBiggestFloat(allResults.ignoredPercentage, ffDecimal, 2) & "%",
    allResults.failedCount, formatBiggestFloat(allResults.failedPercentage, ffDecimal, 2) & "%"
  )
  generateTestResultsPanelGroupPartial(outfile, allResults.data, onlyFailing)
  outfile.generateHtmlTabPageEnd()

proc generateTestRunsHtmlPartial(outfile: File, allResults: AllTests, onlyFailing = false) =
  # Iterating the results twice, get entire result set in one go
  outfile.generateHtmlTabListBegin()
  if allResults.data.len > 0:
    generateTestRunTabListItemPartial(outfile, allResults.data[0], true)
  outfile.generateHtmlTabListEnd()

  outfile.generateHtmlTabContentsBegin()
  var firstRow = true
  for testRunRow in allResults.data:
    generateTestRunTabContentPartial(outfile, allResults, testRunRow, onlyFailing, firstRow)
    if firstRow:
      firstRow = false
  outfile.generateHtmlTabContentsEnd()

proc generateHtml*(filename: string, onlyFailing: bool) =
  var outfile = open(filename, fmWrite)

  outfile.generateHtmlBegin()

  generateTestRunsHtmlPartial(outfile, allTestResults(), onlyFailing)

  outfile.generateHtmlEnd()

  outfile.flushFile()
  close(outfile)
