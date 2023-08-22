# Package

version       = "0.1.0"
author        = "David Anes <kraptor>"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["run"]


# Dependencies

requires "nim >= 0.19.0"


task nodesc, "":
    echo "A task with no description"