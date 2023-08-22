# Package

version       = "0.1.0"
author        = "Dominik Picheta"
description   = "Test package"
license       = "BSD"

# Dependencies

requires "nim >= 0.12.1"

let
  callNimble = getEnv("NIMBLE_TEST_BINARY_PATH")
doAssert callNimble.len != 0, "NIMBLE_TEST_BINARY_PATH not set"

task recurse, "Level 1":
  echo 1
  exec callNimble & " recurse2"

task recurse2, "Level 2":
  echo 2
  exec callNimble & " recurse3"

task recurse3, "Level 3":
  echo 3
