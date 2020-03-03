discard """
action: compile
"""

# See this page for info about the format https://wikitech.wikimedia.org/wiki/Analytics/Data/Pagecounts-all-sites
import tables, parseutils, strutils

const filename = "pagecounts-20150101-050000"

proc parse(filename: string): tuple[projectName, pageTitle: string,
    requests, contentSize: int] =
  # Each line looks like: en Main_Page 242332 4737756101
  var file = open(filename)
  for line in file.lines:
    var i = 0
    var projectName = ""
    i.inc parseUntil(line, projectName, Whitespace, i)
    i.inc
    var pageTitle = ""
    i.inc parseUntil(line, pageTitle, Whitespace, i)
    i.inc
    var requests = 0
    i.inc parseInt(line, requests, i)
    i.inc
    var contentSize = 0
    i.inc parseInt(line, contentSize, i)
    if requests > result[2] and projectName == "en":
      result = (projectName, pageTitle, requests, contentSize)

  file.close()

when true:
  echo parse(filename)
