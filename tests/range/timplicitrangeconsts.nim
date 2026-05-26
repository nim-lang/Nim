discard """
cmd: "nim check $options --hints:off --warning:ImplicitRangeConversion --warningaserror:ImplicitRangeConversion $file"
action: "compile"
"""

type
  E = enum
    ea, eb

  R = range[eb..eb]
  I = range[0..3]

proc accept(r: R) = discard
proc accept(i: I) = discard

var r: R
var i: I
const enumOk = eb
const enumAlias = enumOk
const intOk = 1 + 2

r = eb
r = enumOk
r = enumAlias
accept(eb)
accept(enumOk)
accept(enumAlias)

i = intOk
accept(intOk)
