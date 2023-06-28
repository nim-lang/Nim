discard """
  cmd: "nim $target --threads:on $options $file"
  errormsg: "illegal recursion in type 'TIRC'"
  line: 12
"""

import net
import strutils
import os

type
    TIRC = object
        Socket: Socket
        Thread: Thread[TIRC]

proc initIRC*(): TIRC =
    result.Socket = socket()
