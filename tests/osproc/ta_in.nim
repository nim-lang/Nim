discard """
action: compile
"""

# This file is prefixed with an "a", because other tests
# depend on it and it must be compiled first.
import strutils
let x = stdin.readLine()
echo x.parseInt + 5
