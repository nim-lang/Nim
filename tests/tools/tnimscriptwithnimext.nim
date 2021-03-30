discard """
cmd: "nim e $file"
output: '''
foobar
nothing
hallo
"""

# nimscript files can any extension
import macros

macro foobar(): void =
  result = newCall(bindSym"echo", newLit("nothing"))

echo "foobar"

let x = 123

foobar()

exec "echo hallo"
