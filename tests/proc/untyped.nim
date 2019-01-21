discard """
  errormsg: "'untyped' is only allowed in templates and macros"
  line: 6
"""

proc fun(x:untyped)=discard
fun(10)
