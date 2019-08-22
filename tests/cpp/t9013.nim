discard """
  targets: "cpp"
  cmd: "nim $target --debugger:native $options $file"
"""

# The --debugger switch is needed in order to enable the defined(nimTypeNames)
# code path in hti.nim
import typeinfo
var tt: Any
