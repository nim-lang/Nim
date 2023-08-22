discard """
  errormsg: "'spawn' takes a call expression"
  line: 9
  cmd: "nim $target --threads:on $options $file"
"""

import threadpool

let foo = spawn(1)
