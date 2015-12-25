discard """
  output: "0"
"""

{.hint[XDeclaredButNotUsed]: off.}
var
  x: int

echo x #OUT 0
