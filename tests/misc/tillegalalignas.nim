discard """
cmd: "nim check $options $file"
errormsg: "power of two or 0 expected"
"""

proc foobar() =
  let something {.align(33).} = 123
