discard """
  errormsg: "'array[0..0, typedesc[R[system.int]]]' is not a concrete type"
  line: 7
"""

type R[C] = ref object
  b: C

discard R[[R[int]]]()
