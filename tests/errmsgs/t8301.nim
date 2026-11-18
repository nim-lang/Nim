discard """
  errormsg: "request to generate code for .compileTime proc: foo"
  line: 9
"""

# bug #8301: a proc returning a type used to crash the compiler
proc foo(): auto = void

foo()
