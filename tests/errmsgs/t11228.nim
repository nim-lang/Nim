discard """
  errormsg: "but expected 'Option[system.int]'"
  line: 9
"""

# bug #11228: used to produce invalid C code
import std/options

let a: Option[int] = none(var int)
