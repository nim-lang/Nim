# Package

version       = "0.1.0"
author        = "Ganesh Viswanathan"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["localdeps"]


# Dependencies

requires "nim >= 0.20.2", "https://github.com/nimble-test/packagea"

after install:
  exec "./localdeps"
