discard """
    action: "run"
"""

import strformat

type Obj = object

proc `$`(o: Obj): string = "foobar"

var o: Obj
doAssert fmt"{o}" == "foobar"
doAssert fmt"{o:10}" == "foobar    "

# see issue #7933
var str = "abc"
doAssert fmt">7.1 :: {str:>7.1}" == ">7.1 ::       a"
doAssert fmt">7.2 :: {str:>7.2}" == ">7.2 ::      ab"
doAssert fmt">7.3 :: {str:>7.3}" == ">7.3 ::     abc"
doAssert fmt">7.9 :: {str:>7.9}" == ">7.9 ::     abc"
doAssert fmt">7.0 :: {str:>7.0}" == ">7.0 ::        "
doAssert fmt" 7.1 :: {str:7.1}" == " 7.1 :: a      "
doAssert fmt" 7.2 :: {str:7.2}" == " 7.2 :: ab     "
doAssert fmt" 7.3 :: {str:7.3}" == " 7.3 :: abc    "
doAssert fmt" 7.9 :: {str:7.9}" == " 7.9 :: abc    "
doAssert fmt" 7.0 :: {str:7.0}" == " 7.0 ::        "
doAssert fmt"^7.1 :: {str:^7.1}" == "^7.1 ::    a   "
doAssert fmt"^7.2 :: {str:^7.2}" == "^7.2 ::   ab   "
doAssert fmt"^7.3 :: {str:^7.3}" == "^7.3 ::   abc  "
doAssert fmt"^7.9 :: {str:^7.9}" == "^7.9 ::   abc  "
doAssert fmt"^7.0 :: {str:^7.0}" == "^7.0 ::        "
str = "äöüe\u0309\u0319o\u0307\u0359"
doAssert fmt"^7.1 :: {str:^7.1}" == "^7.1 ::    ä   "
doAssert fmt"^7.2 :: {str:^7.2}" == "^7.2 ::   äö   "
doAssert fmt"^7.3 :: {str:^7.3}" == "^7.3 ::   äöü  "
doAssert fmt"^7.0 :: {str:^7.0}" == "^7.0 ::        "
# this is actually wrong, but the unicode module has no support for graphemes
doAssert fmt"^7.4 :: {str:^7.4}" == "^7.4 ::  äöüe  "
doAssert fmt"^7.9 :: {str:^7.9}" == "^7.9 :: äöüe\u0309\u0319o\u0307\u0359"

# see issue #7932
doAssert fmt"{15:08}" == "00000015" # int, works
doAssert fmt"{1.5:08}" == "000001.5" # float, works
doAssert fmt"{1.5:0>8}" == "000001.5" # workaround using fill char works for positive floats
doAssert fmt"{-1.5:0>8}" == "0000-1.5" # even that does not work for negative floats  
doAssert fmt"{-1.5:08}" == "-00001.5" # works
doAssert fmt"{1.5:+08}" == "+00001.5" # works
doAssert fmt"{1.5: 08}" == " 00001.5" # works

# only add explicitly requested sign if value != -0.0 (neg zero)
doAssert fmt"{-0.0:g}" == "-0"
doassert fmt"{-0.0:+g}" == "-0"
doassert fmt"{-0.0: g}" == "-0"
doAssert fmt"{0.0:g}" == "0"
doAssert fmt"{0.0:+g}" == "+0"
doAssert fmt"{0.0: g}" == " 0"
