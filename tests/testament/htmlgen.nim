#
#
#            Nim Tester
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## HTML generator for the tester.

import db_sqlite, cgi, backend, strutils, json, jquery, bootstrap, testamenthtml

proc generateHtmlBegin(outfile: File) =
  outfile.writeLine(html_begin_1)
  outfile.writeLine(jquery_script_cdn_tag)
  outfile.writeLine(bootstrap_script_cdn_tag)
  outfile.writeLine(bootstrap_style_cdn_tag)
  outfile.writeLine(bootstrap_theme_style_cdn_tag)
  outfile.writeLine(html_begin_2)

proc generateTestRunTabListItemPartial(outfile: File, testRunRow: Row, firstRow = false) =
  let
    # The first tab gets the bootstrap class for a selected tab
    firstTabActiveClass = if firstRow: "active"
                          else: ""
    commitId = testRunRow[0]
    hash = htmlQuote(testRunRow[1])
    branch = htmlQuote(testRunRow[2])
    machineId = testRunRow[3]
    machineName = htmlQuote(testRunRow[4])

  outfile.writeLine(html_tablistitem_format % [
      "firstTabActiveClass", firstTabActiveClass,
      "commitId", commitId,
      "machineId", machineId,
      "branch", branch,
      "hash", hash,
      "machineName", machineName
    ])

proc generateTestResultPanelPartial(outfile: File, testResultRow: Row, onlyFailing = false) =
  let
    trId = testResultRow[0]
    name = testResultRow[1].htmlQuote()
    category = testResultRow[2].htmlQuote()
    target = testResultRow[3].htmlQuote()
    action = testResultRow[4].htmlQuote()
    result = testResultRow[5]
    expected = testResultRow[6]
    gotten = testResultRow[7]
    timestamp = testResultRow[8]
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

  let outputDetails = if expected.isNilOrWhitespace() and gotten.isNilOrWhitespace():
                        html_testresult_no_output
                      else:
                        html_testresult_output_format % [
                          "expected", expected.strip().htmlQuote,
                          "gotten", gotten.strip().htmlQuote
                        ]
  outfile.writeLine(html_testresult_panel_format % [
      "trId", trId,
      "name", name,
      "category", category,
      "target", target,
      "action", action,
      "result", result.htmlQuote(),
      "timestamp", timestamp,
      "outputDetails", outputDetails,
      "panelCtxClass", panelCtxClass,
      "textCtxClass", textCtxClass,
      "bgCtxClass", bgCtxClass,
      "resultSign", resultSign,
      "resultDescription", resultDescription
  ])

proc generateTestResultsPanelGroupParial(outfile: File, db: DbConn, commitid, machineid: string, onlyFailing = false) =
  const testResultsSelect = sql"""
SELECT [tr].[id]
  , [tr].[name]
  , [tr].[category]
  , [tr].[target]
  , [tr].[action]
  , [tr].[result]
  , [tr].[expected]
  , [tr].[given]
  , [tr].[created]
FROM [TestResult] AS [tr]
WHERE [tr].[commit] = ?
  AND [tr].[machine] = ?"""
  for testresultRow in db.rows(testResultsSelect, commitid, machineid):
    generateTestResultPanelPartial(outfile, testresultRow, onlyFailing)

proc generateTestRunTabContentPartial(outfile: File, db: DbConn, testRunRow: Row, onlyFailing = false, firstRow = false) =
  let
    # The first tab gets the bootstrap classes for a selected and displaying tab content
    firstTabActiveClass = if firstRow: " in active"
                          else: ""
    commitId = testRunRow[0]
    hash = htmlQuote(testRunRow[1])
    branch = htmlQuote(testRunRow[2])
    machineId = testRunRow[3]
    machineName = htmlQuote(testRunRow[4])
    os = htmlQuote(testRunRow[5])
    cpu = htmlQuote(testRunRow[6])

  const
    totalClause = """
SELECT COUNT(*)
FROM [TestResult] AS [tr]
WHERE [tr].[commit] = ?
  AND [tr].[machine] = ?"""
    successClause = totalClause & "\L" & """
  AND [tr].[result] LIKE 'reSuccess'"""
    ignoredClause = totalClause & "\L" & """
  AND [tr].[result] LIKE 'reIgnored'"""
  let
    totalCount = db.getValue(sql(totalClause), commitId, machineId).parseBiggestInt()
    successCount = db.getValue(sql(successClause), commitId, machineId).parseBiggestInt()
    successPercentage = 100 * (successCount.toBiggestFloat() / totalCount.toBiggestFloat())
    ignoredCount = db.getValue(sql(ignoredClause), commitId, machineId).parseBiggestInt()
    ignoredPercentage = 100 * (ignoredCount.toBiggestFloat() / totalCount.toBiggestFloat())
    failedCount = totalCount - successCount - ignoredCount
    failedPercentage = 100 * (failedCount.toBiggestFloat() / totalCount.toBiggestFloat())

  outfile.writeLine(html_tabpage_begin_format % [
      "firstTabActiveClass", firstTabActiveClass,
      "commitId", commitId,
      "machineId", machineId,
      "branch", branch,
      "hash", hash,
      "machineName", machineName,
      "os", os,
      "cpu", cpu,
      "totalCount", $totalCount,
      "successCount", $successCount,
      "successPercentage", formatBiggestFloat(successPercentage, ffDecimal, 2) & "%",
      "ignoredCount", $ignoredCount,
      "ignoredPercentage", formatBiggestFloat(ignoredPercentage, ffDecimal, 2) & "%",
      "failedCount", $failedCount,
      "failedPercentage", formatBiggestFloat(failedPercentage, ffDecimal, 2) & "%",
    ])

  generateTestResultsPanelGroupParial(outfile, db, commitId, machineId, onlyFailing)
  
  outfile.writeLine(html_tabpage_end)

proc generateTestRunsHtmlPartial(outfile: File, db: DbConn, onlyFailing = false) =
  # Select a cross-join of Commits and Machines ensuring that the selected combination
  # contains testresults
  const testrunSelect = sql"""
SELECT [c].[id] AS [CommitId]
  , [c].[hash] as [Hash]
  , [c].[branch] As [Branch]
  , [m].[id] AS [MachineId]
  , [m].[name] AS [MachineName]
  , [m].[os] AS [OS]
  , [m].[cpu] AS [CPU]
FROM [Commit] AS [c], [Machine] AS [m]
WHERE (
    SELECT COUNT(*)
    FROM [TestResult] AS [tr]
    WHERE [tr].[commit] = [c].[id]
      AND [tr].[machine] = [m].[id]
  ) > 0
ORDER BY [c].[id] DESC
"""
  # Iterating the results twice, get entire result set in one go
  var testRunRowSeq = db.getAllRows(testrunSelect)

  outfile.writeLine(html_tablist_begin)
  var firstRow = true
  for testRunRow in testRunRowSeq:
    generateTestRunTabListItemPartial(outfile, testRunRow, firstRow)
    if firstRow:
      firstRow = false
  outfile.writeLine(html_tablist_end)

  outfile.writeLine(html_tabcontents_begin)
  firstRow = true
  for testRunRow in testRunRowSeq:
    generateTestRunTabContentPartial(outfile, db, testRunRow, onlyFailing, firstRow)
    if firstRow:
      firstRow = false
  outfile.writeLine(html_tabcontents_end)

proc generateHtml*(filename: string, commit: int; onlyFailing: bool) =
  var db = open(connection="testament.db", user="testament", password="",
                database="testament")
  var outfile = open(filename, fmWrite)

  outfile.generateHtmlBegin()

  generateTestRunsHtmlPartial(outfile, db, onlyFailing)

  outfile.writeLine(html_end)
  
  outfile.flushFile()
  close(outfile)
  close(db)

proc getCommit(db: DbConn, c: int): string =
  var commit = c
  for thisCommit in db.rows(sql"select id from [Commit] order by id desc"):
    if commit == 0: result = thisCommit[0]
    inc commit

proc generateJson*(filename: string, commit: int) =
  const
    selRow = """select count(*),
                           sum(result = 'reSuccess'),
                           sum(result = 'reIgnored')
                from TestResult
                where [commit] = ? and machine = ?
                order by category"""
    selDiff = """select A.category || '/' || A.target || '/' || A.name,
                        A.result,
                        B.result
                from TestResult A
                inner join TestResult B
                on A.name = B.name and A.category = B.category
                where A.[commit] = ? and B.[commit] = ? and A.machine = ?
                   and A.result != B.result"""
    selResults = """select
                      category || '/' || target || '/' || name,
                      category, target, action, result, expected, given
                    from TestResult
                    where [commit] = ?"""
  var db = open(connection="testament.db", user="testament", password="",
                database="testament")
  let lastCommit = db.getCommit(commit)
  if lastCommit.isNil:
    quit "cannot determine commit " & $commit

  let previousCommit = db.getCommit(commit-1)

  var outfile = open(filename, fmWrite)

  let machine = $backend.getMachine(db)
  let data = db.getRow(sql(selRow), lastCommit, machine)

  outfile.writeLine("""{"total": $#, "passed": $#, "skipped": $#""" % data)

  let results = newJArray()
  for row in db.rows(sql(selResults), lastCommit):
    var obj = newJObject()
    obj["name"] = %row[0]
    obj["category"] = %row[1]
    obj["target"] = %row[2]
    obj["action"] = %row[3]
    obj["result"] = %row[4]
    obj["expected"] = %row[5]
    obj["given"] = %row[6]
    results.add(obj)
  outfile.writeLine(""", "results": """)
  outfile.write(results.pretty)

  if not previousCommit.isNil:
    let diff = newJArray()

    for row in db.rows(sql(selDiff), previousCommit, lastCommit, machine):
      var obj = newJObject()
      obj["name"] = %row[0]
      obj["old"] = %row[1]
      obj["new"] = %row[2]
      diff.add obj
    outfile.writeLine(""", "diff": """)
    outfile.writeLine(diff.pretty)

  outfile.writeLine "}"
  close(db)
  close(outfile)

