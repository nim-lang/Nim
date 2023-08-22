# Package

version       = "0.1.0"
author        = "Ivan Bobev"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"

bin = @[projectName()]

import std/os
for name in bin:
  namedBin[name] = name.toDll()

# Dependencies
requires "nim >= 1.5.1"
