discard """
  matrix: "-d:release; -d:danger --checks:on"
  output: "IndexDefect"
"""

# bug #26431: a `{.push checks: off.}` around an import must not disable
# the checks of the imported module.
import m26431a, m26431b

try:
  echo get(@[1, 2, 3], 1_000_000)
except IndexDefect:
  echo "IndexDefect"
