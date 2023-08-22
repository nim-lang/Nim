# Package

version       = "0.1.0"
author        = "dummy"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["tools"]
bin           = @["tools/subbin"]


# Dependencies

requires "nim >= 0.20.0"
