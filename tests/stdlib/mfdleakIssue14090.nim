#[
## issue #14090
this module is to help investigate this issue.
Running this will show that windows fails this test all the time
module named `m` to avoid running it automatically.
]#

import osproc, strutils

proc testFdLeak() =
  let n = 200
  var count = [0,0]
  let options = ["", "-d:nimInheritHandles"]
  for j in 0..<options.len:
    let exe = "tests/stdlib/tfdleak"
    let cmd = "nim c -o:$1 $2 tests/stdlib/tfdleak.nim" % [exe,options[j]]
    echo (j, cmd)
    let (outp1, status1) = execCmdEx(cmd)
    doAssert status1 == 0, outp1
    for i in 0..<n:
      let cmd2 = exe
      echo (j, i, n, cmd2)
      let (outp, status) = execCmdEx(cmd2)
      doAssert status == 0
      if "leaked" in outp:
        count[j].inc
        echo count, "\n", outp
  doAssert count == [0,0], $count

when isMainModule: testFdLeak()
