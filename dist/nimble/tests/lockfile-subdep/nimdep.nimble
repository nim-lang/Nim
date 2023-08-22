# Package

version       = "0.1.0"
author        = "Ivan Yonchovski"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim"
taskRequires "test", "sdl2_nim"

task test, "...":
  echo "test"
