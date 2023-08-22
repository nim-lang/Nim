# Package

version       = "0.1.0"
author        = "Dominik Picheta"
description   = "Package reproducing issues depending on #head and concrete version of the same package."
license       = "MIT"

bin = @["issue289"]

# Dependencies

requires "nim >= 0.15.0", "https://github.com/nimble-test/packagea.git 0.6.0"
requires "https://github.com/nimble-test/packagea.git#head"

