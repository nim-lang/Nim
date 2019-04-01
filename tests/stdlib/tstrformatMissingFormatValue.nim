discard """
errormsg: '''type mismatch: got <string, Obj, string>'''
nimout: '''proc formatValue'''
"""

# This test is here to make sure that there is a clean error that
# that indicates ``formatValue`` needs to be overloaded with the custom type.

import strformat

type Obj = object

proc `$`(o: Obj): string = "foobar"

var o: Obj
doAssert fmt"{o}" == "foobar"
