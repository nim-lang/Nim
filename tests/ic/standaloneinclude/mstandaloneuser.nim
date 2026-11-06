import mstandalonehw

proc user*(x: uint8): uint8 = hwWrite(x) shr 1
