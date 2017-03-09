[Package]
name          = "nimsuggest"
version       = "0.1.0"
author        = "Andreas Rumpf"
description   = "Tool for providing auto completion data for Nim source code."
license       = "MIT"

bin = "nimsuggest"

[Deps]
Requires: "nim >= 0.11.2, compiler#head"
