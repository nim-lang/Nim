## This module is a sample.

import strutils

proc helloWorld*(times: int) =
  ## Takes an integer and outputs
  ## as many "hello world!"s

  for i in 0 .. times-1:
    echo "hello world!"

helloWorld(5)
