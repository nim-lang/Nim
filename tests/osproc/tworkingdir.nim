discard """
  file: "tworkingdir.nim"
  output: ""
"""

import osproc, os

let dir1 = getCurrentDir()
var process = startProcess("/usr/bin/true", "/usr/bin")
let dir2 = getCurrentDir()
discard process.waitForExit()
process.close()
doAssert(dir1 == dir2)
