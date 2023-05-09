version = "1.0.0"
author = "disruptek"
description = "a cure for salty testes"
license = "MIT"

#requires "cligen >= 0.9.41 & <= 0.9.45"
#requires "bump >= 1.8.18 & < 2.0.0"
requires "https://github.com/disruptek/grok >= 0.0.4 & < 1.0.0"
requires "https://github.com/juancarlospaco/nim-bytes2human"

bin = @["testes"]           # build the binary for basic test running
installExt = @["nim"]       # we need to install testes.nim also
skipDirs = @["tests"]       # so stupid...  who doesn't want tests?

task test, "run tests for ci":
  exec "nim c --run testes.nim"

task demo, "produce a demo":
  when (NimMajor, NimMinor) != (1, 0):
    echo "due to nim bug #16307, use nim-1.0"
    quit 1
  exec """demo docs/demo.svg "nim c --out=\$1 examples/balls.nim""""
  exec """demo docs/clean.svg "nim c --define:danger --out=\$1 tests/testicles.nim""""
