discard """
  output: "#FFC0CB"
"""

{.experimental: "typeImports".}

from colors import Color

# to string and proc imported
let pink = rgb(255, 192, 203)
echo $pink
