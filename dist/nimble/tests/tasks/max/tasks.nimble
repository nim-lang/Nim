# Package

version       = "0.1.0"
author        = "David Anes <kraptor>"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["run"]


# Dependencies

requires "nim >= 0.19.0"


task task1, "Description1":
    echo "blah"

task very_long_task, "This is a task with a long name":
    echo "blah"

task aaa, "A task with a small name":
    echo "blah"