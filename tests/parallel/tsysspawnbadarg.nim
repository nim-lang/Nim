discard """
  file: "tsysspawnbadarg.nim"
  # line: 10
  errormsg: "'spawn' takes a call expression"
  cmd: "nim $target --threads:on $options $file"
"""

import threadpool

let foo = spawn(1)
