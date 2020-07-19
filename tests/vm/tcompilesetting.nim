discard """
cmd: "nim c --nimcache:build/myNimCache --nimblePath:myNimblePath $file"
joinable: false
"""

import strutils

import std / compilesettings

const
  nc = querySetting(nimcacheDir)
  np = querySettingSeq(nimblePaths)

static:
  echo nc
  echo np

doAssert "myNimCache" in nc
doAssert "myNimblePath" in np[0]
doAssert querySetting(backend) == "c"

block:
  setCapturedMsgs(captureStart)
  proc fun(){.deprecated.} = discard
  {.push warning[Deprecated]: on.}
  fun()
  {.pop.}
  doAssert "Warning: fun is deprecated [Deprecated]" in getCapturedMsgs()
  {.push warning[Deprecated]: off.}
  fun()
  {.pop.}
  doAssert "Warning: fun is deprecated [Deprecated]" notin getCapturedMsgs()
  # fun() # uncommenting this would cause error: `conf.capturedMsgs.len == 0` capturedMsgs not empty:
  # which is by design: you must call `getCapturedMsgs()` before it.
  setCapturedMsgs(captureStop)
