discard """
cmd: "nim c --nimcache:build/myNimCache --nimblePath:myNimblePath $file"
joinable: false
"""

import std/[strutils,compilesettings]
from std/os import fileExists, `/`

template main =
  doAssert querySetting(nimcacheDir) == nimcacheDir.querySetting
  doAssert "myNimCache" in nimcacheDir.querySetting
  doAssert "myNimblePath" in nimblePaths.querySettingSeq[0]
  doAssert querySetting(backend) == "c"
  doAssert fileExists(libPath.querySetting / "system.nim")

static: main()
main()
