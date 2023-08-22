# Package

version       = "0.1.0"
author        = "Ivan Yonchovski"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["demo"]

# Dependencies

requires "nim"

task version, "Test nim version":
  exec "nim --version"
