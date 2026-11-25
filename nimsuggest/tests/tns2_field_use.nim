# `use` of an object field also lists its uses in the other modules, read
# from their NIFs. A field's NIF name is shared by the same-named field at
# that position of every type, so each use is checked by loading the routine
# it is in, also when that is a nested routine or a generic instance:
# `Other.x` and `useOther` are not listed. From `mns2fieldlib`,
# compiled from source, its field is another symbol than the one the other
# modules load; the use at this module's top level is in no routine, so it
# cannot be checked and is not listed.

import mns2fieldlib, mns2fielduse

var p = newPoint()
discard p.x

discard """
$nimsuggest2 $file
>changed $file
>use $file:13:10
def;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fieldlib.nim;;3;;4;;""
use;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fieldlib.nim;;7;;32;;""
use;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fielduse.nim;;3;;34;;""
use;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fielduse.nim;;6;;24;;""
use;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fielduse.nim;;8;;45;;""
use;;skField;;mns2fieldlib.Point.x;;int;;$file;;13;;10;;""
>use $path/mns2fieldlib.nim:3:4
def;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fieldlib.nim;;3;;4;;""
use;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fieldlib.nim;;7;;32;;""
use;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fielduse.nim;;3;;34;;""
use;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fielduse.nim;;6;;24;;""
use;;skField;;mns2fieldlib.Point.x;;int;;*/mns2fielduse.nim;;8;;45;;""
"""
