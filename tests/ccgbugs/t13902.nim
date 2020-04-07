discard """
  cmd: "nim c -r --skipParentCfg --skipUserCfg --cpu:i386 --passC:-m32 --passL:-m32 --stacktrace:off --hints:off $file"
  action: run
"""

#issue #13902
when defined(linux):
  block:
    type Slot = distinct uint64
    var s = Slot(1)
    proc `$`(x: Slot): string {.borrow.}
    proc `+=`(x: var Slot, y: uint64) {.borrow.}
    echo "s = ", s
    s += 1
    echo "s = ", s
    doAssert s.uint64 == 2, $s # was failing, showing 18419607611339964418
