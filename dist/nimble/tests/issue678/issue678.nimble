# Package

version     = "0.1.0"
author      = "Ivan Bobev"
description = "Package for ensuring that issue #678 is resolved."
license     = "MIT"

# Dependencies

requires "nim >= 0.19.6"
# to reproduce dependency 2 must be before 1
requires "issue678_dependency_2", "issue678_dependency_1"
