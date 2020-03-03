# Package

version       = "0.1.0"
author        = "Dominik Picheta"
description   = "A simple Twitter clone developed in Nim in Action."
license       = "MIT"

bin = @["tweeter"]
skipExt = @["nim"]

# Dependencies

requires "nim >= 0.13.1"
requires "jester >= 0.0.1"
