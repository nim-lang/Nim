
#issue #13902
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
