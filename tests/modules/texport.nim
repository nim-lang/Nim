discard """
  output: "my object68"
"""

import mexporta

# bug #1029:
from rawsockets import accept

# B.TMyObject has been imported implicitly here: 
var x: TMyObject
echo($x, q(0), q"0")

