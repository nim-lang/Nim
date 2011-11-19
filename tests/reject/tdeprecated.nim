discard """
  line: 9
  errmsg: "'a' is deprecated [Deprecated]"
"""

var
  a {.deprecated.}: array[0..11, int]
  
a[8] = 1


