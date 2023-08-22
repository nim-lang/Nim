discard """
action: compile
"""

# See this page for info about the format https://wikitech.wikimedia.org/wiki/Analytics/Data/Pagecounts-all-sites
import tables, parseutils, strutils, threadpool, re

const filename = "pagecounts-20160101-050000"

type
  Stats = ref object
    projectName, pageTitle: string
    requests, contentSize: int

proc `$`(stats: Stats): string =
  "(projectName: $#, pageTitle: $#, requests: $#, contentSize: $#)" % [
    stats.projectName, stats.pageTitle, $stats.requests, $stats.contentSize
  ]

proc parse(chunk: string): Stats =
  # Each line looks like: en Main_Page 242332 4737756101
  result = Stats(projectName: "", pageTitle: "", requests: 0, contentSize: 0)

  var matches: array[4, string]
  var reg = re"([^\s]+)\s([^\s]+)\s(\d+)\s(\d+)"
  for line in chunk.splitLines:

    let start = find(line, reg, matches)
    if start == -1: continue

    let requestsInt = matches[2].parseInt
    if requestsInt > result.requests and matches[0] == "en":
      result = Stats(
        projectName: matches[0],
        pageTitle: matches[1],
        requests: requestsInt,
        contentSize: matches[3].parseInt
      )

proc readChunks(filename: string, chunksize = 1000000): Stats =
  result = Stats(projectName: "", pageTitle: "", requests: 0, contentSize: 0)
  var file = open(filename)
  var responses = newSeq[FlowVar[Stats]]()
  var buffer = newString(chunksize)
  var oldBufferLen = 0
  while not endOfFile(file):
    let readSize = file.readChars(buffer, oldBufferLen, chunksize - oldBufferLen) + oldBufferLen
    var chunkLen = readSize

    while chunkLen >= 0 and buffer[chunkLen - 1] notin NewLines:
      # Find where the last line ends
      chunkLen.dec

    responses.add(spawn parse(buffer[0 ..< chunkLen]))
    oldBufferLen = readSize - chunkLen
    buffer[0 ..< oldBufferLen] = buffer[readSize - oldBufferLen .. ^1]

  echo("Spawns: ", responses.len)
  for resp in responses:
    let statistic = ^resp
    if statistic.requests > result.requests:
      result = statistic

  file.close()


when true:
  echo readChunks(filename)
