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
    when sizeof(int) == 4 or defined(linux):
      const nim = getCurrentCompilerExe()
      const file = currentSourcePath()
      var options = ""
      when sizeof(int) == 8:
        when defined(linux): # other OS would need custom cross compile libs
          options = "--cpu:i386 --passC:-m32 --passL:-m32"
        else:
          if true: return
      let cmd = fmt"{nim} c -r {options} -d:case_t13902 --skipParentCfg --skipUserCfg --stacktrace:off --hints:off {file}"
      let (output, exitCode) = execCmdEx(cmd)
      doAssert exitCode == 0, cmd & "\n" & output
  main()
