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
