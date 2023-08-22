# Package

version       = "0.1.0"
author        = "Ganesh Viswanathan"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["issue793"]

# Dependencies

requires "nim >= 0.20.2"

before build:
  echo "before build"
after build:
  echo "after build"

# Issue 776
before doc:
  echo "before doc"
after doc:
  echo "after doc"