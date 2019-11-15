discard """
cmd: "nim check $options $file"
errormsg: "power of two or 0 expected"
"""

proc foobar() =
  let something {.alignas(33).} = 123
