discard """
  matrix: "--parsem:on"
  errormsg: "undeclared identifier: 'b'"
  line: 9
"""

# A compile-time evaluation sems the bodies it needs right there, against the
# scope as it is at that point: `b` is not declared yet.
proc a(): int = b()
const x = a()
proc b(): int = 1
echo x
