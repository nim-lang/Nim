# Package

version     = "0.1.0"
author      = "GT"
description = "Package for ensuring that issue #633 is resolved."
license     = "MIT"

# Dependencies

requires "nim >= 0.19.6"
# to reproduce dependency 2 must be before 1

task testTask, "Test":
  for i in 0 .. paramCount():
    if paramStr(i) == "--testTask":
      echo "Got it"
