# Package

version       = "0.1.0"
author        = "nim-lang"
description   = "SMTP client implementation (originally in the stdlib)."
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 0.15.0"

task compileExample, "compiles client example":
  exec "nim c examples/client_example"
