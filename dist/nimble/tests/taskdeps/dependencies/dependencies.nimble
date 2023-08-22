# Package

version       = "0.1.0"
author        = "John Doe"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "."
bin           = @["foo"]


# Dependencies

requires "nim >= 0.19.0"

taskRequires "test", "unittest2 == 0.0.4"
