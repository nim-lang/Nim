# bug #11502: a seq of pointers in the VM
type
  Option = object
    val: bool

proc test =
  var opt = Option(val: false)
  var options = @[addr opt]
  options[0].val = true
  doAssert opt.val == true

static: test()
test()
