include "lib/system/compilation.nim"
version = $NimMajor & "." & $NimMinor & "." & $NimPatch
author = "Andreas Rumpf"
description = "Nim package providing the compiler binary"
license = "MIT"

bin = @["compiler/nim", "nimsuggest/nimsuggest"]
skipFiles = @["azure-pipelines.yml" , "build_all.bat" , "build_all.sh" , "build_nimble.bat" , "build_nimble.sh" , "changelog.md" , "koch.nim.cfg" , "nimblemeta.json" , "readme.md" , "security.md" ]
skipDirs = @["build" , "changelogs" , "ci" , "csources_v2" , "drnim" , "nimdoc", "testament"]

before install:
  when defined(windows):
    if not "bin\nim.exe".fileExists:
      exec "build_all.bat"
  else:
    if not "bin/nim".fileExists:
      exec "./build_all.sh"
