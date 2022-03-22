version = "3.4.1"
author = "disruptek"
description = "a unittest framework with balls 🔴🟡🟢"
license = "MIT"

# requires newTreeFrom
requires "https://github.com/disruptek/grok >= 0.5.0 & < 1.0.0"
requires "https://github.com/disruptek/ups < 1.0.0"
requires "https://github.com/planetis-m/sync#810bd2d"
#requires "https://github.com/c-blake/cligen < 2.0.0"

bin = @["balls"]            # build the binary for basic test running
installExt = @["nim"]       # we need to install balls.nim also
skipDirs = @["tests"]       # so stupid...  who doesn't want tests?
#installFiles = @["balls.nim"] # https://github.com/nim-lang/Nim/issues/16661

task test, "run tests for ci":
  when defined(windows):
    exec "balls.cmd"
  else:
    exec "balls"

task demo, "produce a demo":
  exec "nim c --define:release balls.nim"
  when (NimMajor, NimMinor) != (1, 0):
    echo "due to nim bug #16307, use nim-1.0"
    quit 1
  exec """demo docs/demo.svg "nim c --out=\$1 examples/fails.nim""""
  exec """demo docs/clean.svg "nim c --define:danger -f --out=\$1 tests/test.nim""""
  exec "nim c --define:release --define:ballsDry balls.nim"
  exec """demo docs/runner.svg "balls""""

