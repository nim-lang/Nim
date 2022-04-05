discard """
  matrix: "--threads:on"
  errormsg: "'spawn'ed function cannot have a 'typed' or 'untyped' parameter"
"""

# bug #9691

import threadpool
spawn echo()
