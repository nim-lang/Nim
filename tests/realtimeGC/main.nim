discard """
  cmd: "nim $target --debuginfo $options $file"
  output: "Done"
"""

import times
import os

const RUNTIME = 35 * 60 # 35 minutes

when defined(windows):
  const dllname = "./shared.dll"
elif defined(macosx):
  const dllname = "./libshared.dylib"
else:
  const dllname = "./libshared.so"

proc status() {.importc: "status", dynlib: dllname.}
proc count() {.importc: "count", dynlib: dllname.}
proc occupiedMem() {.importc: "occupiedMem", dynlib: dllname.}

proc main() =
  let startTime = getTime()
  let runTime = cast[Time](RUNTIME) #
  var accumTime: Time
  while accumTime < runTime:
    for i in 0..10:
      count()
    #echo("1. sleeping... ")
    sleep(500)
    for i in 0..10:
      status()
    #echo("2. sleeping... ")
    sleep(500)
    occupiedMem()
    accumTime = cast[Time]((getTime() - startTime))
    #echo("--- Minutes left to run: ", int(int(runTime-accumTime)/60))
  echo("Done")

main()
