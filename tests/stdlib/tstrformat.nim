discard """
    action: "run"
"""

import strformat

type Obj = object

proc `$`(o: Obj): string = "foobar"

var o: Obj
doAssert fmt"{o}" == "foobar"
doAssert fmt"{o:10}" == "foobar    "

doAssert fmt"{-0.0:g}" == "-0"
doassert fmt"{-0.0:+g}" == "-0"
doAssert fmt"{0.0:g}" == "0"
doAssert fmt"{0.0:+g}" == "+0"