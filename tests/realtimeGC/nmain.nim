discard """
  cmd: "nim $target --debuginfo $options $file"
  output: "Done"
"""

import times, os, threadpool

const RUNTIME = 15 * 60 # 15 minutes

when defined(windows):
  const dllname = "./tests/realtimeGC/shared.dll"
elif defined(macosx):
  const dllname = "./tests/realtimeGC/libshared.dylib"
else:
  const dllname = "./tests/realtimeGC/libshared.so"

proc status() {.importc: "status", dynlib: dllname.}
proc count() {.importc: "count", dynlib: dllname.}
proc checkOccupiedMem() {.importc: "checkOccupiedMem", dynlib: dllname.}

proc process() =
  let startTime = getTime()
  let runTime = cast[Time](RUNTIME) #
  var accumTime: Time
  while accumTime < runTime:
    for i in 0..10:
      count()
    # echo("1. sleeping... ")
    sleep(500)
    for i in 0..10:
      status()
    # echo("2. sleeping... ")
    sleep(500)
    checkOccupiedMem()
    accumTime = cast[Time]((getTime() - startTime))
    # echo("--- Minutes left to run: ", int(int(runTime-accumTime)/60))

proc main() =
  process()
  # parallel:
  #   for i in 0..0:
  #     spawn process()
  # sync()
  echo("Done")

main()
