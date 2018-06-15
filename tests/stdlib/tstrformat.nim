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

# add thousands separator
doAssert fmt("{high(int32):#,d}") == "2,147,483,647"
doAssert fmt("{high(int32):#,x}") == "0x7fff_ffff"
doAssert fmt("{high(int32):#,b}") == "0b111_1111_1111_1111_1111_1111_1111_1111"
doAssert fmt("{high(int32):#,o}") == "0o17_777_777_777"

doAssert fmt("{-1:+015,d}") == "-00000000000001"
doAssert fmt("{-123:+015,d}") == "-00000000000123"
doAssert fmt("{-1234:+015,d}") == "-0000000001,234"
doAssert fmt("{12345:+015,d}") == "+0000000012,345"
doAssert fmt("{123456: 15,d}") == "        123,456"
doAssert fmt("{1234567: 15,d}") == "      1,234,567"
doAssert fmt("{12345678:+015'd}") == "+000012'345'678"
doAssert fmt("{123456789:+015'd}") == "+000123'456'789"
doAssert fmt("{1234567890:+015'd}") == "+01'234'567'890"
doAssert fmt("{12345678901:+015,d}") == "+12,345,678,901"
doAssert fmt("{123456789012:+015,d}") == "+123,456,789,012"
doAssert fmt("{1234567890123:+015,d}") == "+1,234,567,890,123"

doAssert fmt("{float(low(int32)) - 1.1e10:+30'.20e}") == "   -1.31474836480000000000e+10"
doAssert fmt("{float(low(int32)) - 0.1:+30'.11g}") == "              -2'147'483'648.1"
doAssert fmt("{float(high(int32)) + 0.1234567: 30,.6f}") == "          2,147,483,647.123457"

# check '_' and ' ' as separators and off by one error in floats
doAssert fmt("{123.123:6_.3f}") == "123.123"
doAssert fmt("{1234.123:6_.3f}") == "1_234.123"
doAssert fmt("{123.123:7 .3f}") == "123.123"
doAssert fmt("{1234.123:7 .3f}") == "1 234.123"