discard """
action: compile
"""

import os, parseutils, threadpool, strutils

type
  Stats = ref object
    domainCode, pageTitle: string
    countViews, totalSize: int

proc newStats(): Stats =
  Stats(domainCode: "", pageTitle: "", countViews: 0, totalSize: 0)

proc `$`(stats: Stats): string =
  "(domainCode: $#, pageTitle: $#, countViews: $#, totalSize: $#)" % [
    stats.domainCode, stats.pageTitle, $stats.countViews, $stats.totalSize
  ]

proc parse(line: string, domainCode, pageTitle: var string,
    countViews, totalSize: var int) =
  if line.len == 0: return
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

proc parseChunk(chunk: string): Stats =
  result = newStats()
  var domainCode = ""
  var pageTitle = ""
  var countViews = 0
  var totalSize = 0
  for line in splitLines(chunk):
    parse(line, domainCode, pageTitle, countViews, totalSize)
    if domainCode == "en" and countViews > result.countViews:
      result = Stats(domainCode: domainCode, pageTitle: pageTitle,
                     countViews: countViews, totalSize: totalSize)

proc readPageCounts(filename: string, chunkSize = 1_000_000) =
  var file = open(filename)
  var responses = newSeq[FlowVar[Stats]]()
  var buffer = newString(chunksize)
  var oldBufferLen = 0
  while not endOfFile(file):
    let reqSize = chunksize - oldBufferLen
    let readSize = file.readChars(buffer, oldBufferLen, reqSize) + oldBufferLen
    var chunkLen = readSize

    while chunkLen >= 0 and buffer[chunkLen - 1] notin NewLines:
      chunkLen.dec

    responses.add(spawn parseChunk(buffer[0 ..< chunkLen]))
    oldBufferLen = readSize - chunkLen
    buffer[0 ..< oldBufferLen] = buffer[readSize - oldBufferLen .. ^1]

  var mostPopular = newStats()
  for resp in responses:
    let statistic = ^resp
    if statistic.countViews > mostPopular.countViews:
      mostPopular = statistic

  echo("Most popular is: ", mostPopular)

when true:
  const file = "pagecounts-20160101-050000"
  let filename = getCurrentDir() / file
  readPageCounts(filename)
