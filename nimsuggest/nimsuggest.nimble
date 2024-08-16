include "../lib/system/compilation.nim"
version = $NimMajor & "." & $NimMinor & "." & $NimPatch
author = "Andreas Rumpf"
description = "Tool for providing auto completion data for Nim source code."
license = "MIT"
bin = @["nimsuggest"]

requires "compiler >= 1.9.0" , "checksums"
