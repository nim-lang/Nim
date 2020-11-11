## This module is a sample.

import strutils

proc helloWorld*(times: int) =
  ## Takes an integer and outputs
  ## as many indented "hello world!"s

  for i in 0 .. times-1:
    echo "hello world!".indent(2) # using indent to avoid `UnusedImport`

helloWorld(5)
