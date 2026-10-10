import mimports
doAssert fn1() == 1
doAssert not declared(hfn3)

#!EDIT!#

import mimports {.all.}
doAssert fn1() == 1
doAssert declared(hfn3)
doAssert hfn3() == 3
doAssert mimports.hfn4() == 4

# reexports
doAssert not declared(fnb1)
doAssert not declared(hfnb4)
doAssert fnb2() == 2
doAssert hfnb3() == 3

#!EDIT!#

from mimports {.all.} import hfn3
doAssert not declared(fn1)
from mimports {.all.} as bar import fn1
doAssert fn1() == 1
doAssert hfn3() == 3
doAssert not declared(hfn4)
doAssert declared(mimports.hfn4)
doAssert mimports.hfn4() == 4
doAssert bar.hfn4() == 4
