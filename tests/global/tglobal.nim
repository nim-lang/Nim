discard """
  output: "in globalaux2: 10\Ntotal globals: 2\Nint value: 100\Nstring value: second"
  disabled: "true"
"""

import globalaux, globalaux2

echo "total globals: ", totalGlobals

globalInstance[int]().val = 100
echo "int value: ", globalInstance[int]().val

globalInstance[string]().val = "first"
globalInstance[string]().val = "second"
echo "string value: ", globalInstance[string]().val

