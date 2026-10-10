discard """
  cmd: "nim check $file"
  action: "reject"
  errormsg: "'let' symbol requires an initialization"
"""

# `nim check` used to crash on this after the first error
# bug #21027
let x: uint64 = cast(5)
