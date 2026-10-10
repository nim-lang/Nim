discard """
  errormsg: "ambiguous sum type branch 'None'; use a type conversion to select one of: msumtypes.Opt msumtypes_clash.Res"
  line: 8
"""

import msumtypes, msumtypes_clash

echo None()
