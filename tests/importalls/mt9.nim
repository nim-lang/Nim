# tests re-export of a module with import {.all.}

import ./m4

doAssert m3p1 == 2
doAssert not declared(m3h2)
doAssert m3h3 == 3
doAssert m3h4 == 4

doAssert bar1 == 2
doAssert bar2 == 2
doAssert not declared(bar3)
