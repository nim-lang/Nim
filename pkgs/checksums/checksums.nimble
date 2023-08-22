# Package

version       = "0.1.0"
author        = "Nim Contributors"
description   = "Hash algorithms in Nim."
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.12"

task docs, "Generate documentaion":
  exec "nim doc --project --docroot --outdir:htmldocs --styleCheck:hint src/checksums/docutils.nim"
