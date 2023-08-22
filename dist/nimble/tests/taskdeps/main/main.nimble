# Package

version       = "0.1.0"
author        = "John Doe"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @[]


# Dependencies

requires "nim >= 0.19.0"

taskRequires "benchmark", "benchy == 0.0.1"
taskRequires "test", "unittest2 == 0.0.4"

task benchmark, "Runs benchmarks":
  setCommand("c", "benchmark")
