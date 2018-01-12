discard """
    action: "run"
"""

import strformat

type Obj = object

proc `$`(o: Obj): string = "foobar"

var o: Obj
doAssert %"{o}" == "foobar"
doAssert %"{o:10}" == "foobar    "