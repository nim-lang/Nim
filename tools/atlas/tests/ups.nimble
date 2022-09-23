version = "0.0.2"
author = "disruptek"
description = "a package handler"
license = "MIT"

requires "npeg >= 0.23.2 & < 1.0.0"
requires "https://github.com/disruptek/testes >= 1.0.0 & < 2.0.0"

task test, "run tests":
  when defined(windows):
    exec "testes.cmd"
  else:
    exec findExe"testes"
