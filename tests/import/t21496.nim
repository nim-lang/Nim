discard """
  errormsg: "redefinition of 'm21496'; previous declaration here: t21496.nim(5, 12)"
"""

import fizz/m21496, buzz/m21496

# bug #21496

m21496.fb()
