discard """
  errormsg: "'typed' is only allowed in templates and macros"
  line: 6
"""

proc fun(x:typed)=discard
fun(10)
