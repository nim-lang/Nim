discard """
    action: "run"
"""

import strformat

type Obj = object

proc `$`(o: Obj): string = "foobar"

var o: Obj
doAssert fmt"{o}" == "foobar"
doAssert fmt"{o:10}" == "foobar    "