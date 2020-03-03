discard """
action: compile
"""

# See this page for info about the format https://wikitech.wikimedia.org/wiki/Analytics/Data/Pagecounts-all-sites
import tables, parseutils, strutils, threadpool

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

  var projectName = ""
  var pageTitle = ""
  var requests = ""
  var contentSize = ""
  for line in chunk.splitLines:
    var i = 0
    projectName.setLen(0)
    i.inc parseUntil(line, projectName, Whitespace, i)
    i.inc skipWhitespace(line, i)
    pageTitle.setLen(0)
    i.inc parseUntil(line, pageTitle, Whitespace, i)
    i.inc skipWhitespace(line, i)
    requests.setLen(0)
    i.inc parseUntil(line, requests, Whitespace, i)
    i.inc skipWhitespace(line, i)
    contentSize.setLen(0)
    i.inc parseUntil(line, contentSize, Whitespace, i)
    i.inc skipWhitespace(line, i)

    if requests.len == 0 or contentSize.len == 0:
      # Ignore lines with either of the params that are empty.
      continue

    let requestsInt = requests.parseInt
    if requestsInt > result.requests and projectName == "en":
      result = Stats(
        projectName: projectName,
        pageTitle: pageTitle,
        requests: requestsInt,
        contentSize: contentSize.parseInt
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

  for resp in responses:
    let statistic = ^resp
    if statistic.requests > result.requests:
      result = statistic

  file.close()


when true:
  echo readChunks(filename)
