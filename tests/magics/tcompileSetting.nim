discard """
cmd: "nim c --nimcache:myNimCache --nimblePath:myNimblePath $file"
joinable: false
"""

import strutils

const
  nc = compileSetting("nimcachedir")
  np = compileSettingSeq("nimblePaths")

static:
  echo nc
  echo np

doAssert "myNimCache" in nc
doAssert "myNimblePath" in np[0]
