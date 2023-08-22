version       = "0.1.0"
author        = "John Doe"
description   = "Nimble Test"
license       = "BSD"

skipFiles = @["myTester.nim"]

task test, "Custom tester":
  when defined(CUSTOM):
    exec "nim c -r myTester.nim"
    echo commandLineParams.contains("--runflag")