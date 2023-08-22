# Package

version       = "0.1.0"
author        = "Hitesh Jasani"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["issue801"]

# Dependencies

requires "timezones"

before test:
   echo "before test"
after test:
  echo "after test"