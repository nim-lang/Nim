# Package

version       = "0.1.0"
author        = "Ivan Yonchovski"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["run"]


# Dependencies

requires "benchy", "unittest2"

task echoPaths, "":
    echo getPaths()
    echo getPathsClause()
