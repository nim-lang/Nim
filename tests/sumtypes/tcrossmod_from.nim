discard """
  output: '''
(`kind: Some, val: 1) (`kind: Some, val: 2)
(`kind: Some, val: 3)
'''
"""

# importing or exporting a sum type brings its branch names along, like
# the fields of an enum:
from msumtypes import Opt
import msumtypes_reexport as r

let x: Opt[int] = Some(val: 1)
echo x, " ", msumtypes.Some(val: 2)
let y: r.Opt[int] = Some(val: 3)
echo y
