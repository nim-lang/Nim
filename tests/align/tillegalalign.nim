discard """
cmd: "nim check $options $file"
errormsg: "power of two expected"
"""

proc foobar() =
  let something {.align(33).} = 123
