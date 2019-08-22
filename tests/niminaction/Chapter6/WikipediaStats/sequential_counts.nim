discard """
action: compile
"""

import os, parseutils

proc parse(line: string, domainCode, pageTitle: var string,
    countViews, totalSize: var int) =
  var i = 0
  domainCode.setLen(0)
  i.inc parseUntil(line, domainCode, {' '}, i)
  i.inc
  pageTitle.setLen(0)
  i.inc parseUntil(line, pageTitle, {' '}, i)
  i.inc
  countViews = 0
  i.inc parseInt(line, countViews, i)
  i.inc
  totalSize = 0
  i.inc parseInt(line, totalSize, i)

proc readPageCounts(filename: string) =
  var domainCode = ""
  var pageTitle = ""
  var countViews = 0
  var totalSize = 0
  var mostPopular = ("", "", 0, 0)
  for line in filename.lines:
    parse(line, domainCode, pageTitle, countViews, totalSize)
    if domainCode == "en" and countViews > mostPopular[2]:
      mostPopular = (domainCode, pageTitle, countViews, totalSize)

  echo("Most popular is: ", mostPopular)

when true:
  const file = "pagecounts-20160101-050000"
  let filename = getCurrentDir() / file
  readPageCounts(filename)
