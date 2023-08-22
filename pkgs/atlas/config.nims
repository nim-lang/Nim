
task build, "Build local atlas":
  exec "nim c -d:debug -o:./atlas src/atlas.nim"

task unitTests, "Runs unit tests":
  exec "nim c -d:debug -r tests/unittests.nim"

task tester, "Runs integration tests":
  exec "nim c -d:debug -r tests/tester.nim"

task test, "Runs all tests":
  # unitTestsTask() # tester runs both
  testerTask()
