#issue #13902
when defined case_t13902:
  block:
    type Slot = distinct uint64
    var s = Slot(1)
    proc `$`(x: Slot): string {.borrow.}
    proc `+=`(x: var Slot, y: uint64) {.borrow.}
    # test was failing with either 0 or 2 echos but not with 1 echo
    # echo "s = ", s
    s += 1
    # echo "s = ", s
    doAssert s.uint64 == 2, $s # was failing, showing 18419607611339964418

else:
  import std/[strformat,os,osproc]
  proc main() =
    when defined(linux):
      # osx doesn't support 32bit and windows doesn't have the required
      # cross compilation libraries by default
      const nim = getCurrentCompilerExe()
      const file = currentSourcePath()
      let cmd = fmt"{nim} c -r -d:case_t13902 --skipParentCfg --skipUserCfg --cpu:i386 --passC:-m32 --passL:-m32 --stacktrace:off --hints:off {file}"
      let (output, exitCode) = execCmdEx(cmd)
      doAssert exitCode == 0, $(cmd, output)
  main()
