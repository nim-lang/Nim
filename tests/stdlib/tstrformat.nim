discard """
action: "run"
output: '''Received (name: "Foo", species: "Bar")'''
"""

import strformat

type Obj = object

proc `$`(o: Obj): string = "foobar"

# for custom types, formatValue needs to be overloaded.
template formatValue(result: var string; value: Obj; specifier: string) =
  result.formatValue($value, specifier)

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

# seq format

let data1 = [1'i64, 10000'i64, 10000000'i64]
let data2 = [10000000'i64, 100'i64, 1'i64]

proc formatValue(result: var string; value: (array|seq|openArray); specifier: string) =
  result.add "["
  for i, it in value:
    if i != 0:
      result.add ", "
    result.formatValue(it, specifier)
  result.add "]"

doAssert fmt"data1: {data1:8} #" == "data1: [       1,    10000, 10000000] #"
doAssert fmt"data2: {data2:8} =" == "data2: [10000000,      100,        1] ="

# custom format Value

type
  Vec2[T] = object
    x,y: T

proc formatValue[T](result: var string; value: Vec2[T]; specifier: string) =
  result.add '['
  result.formatValue value.x, specifier
  result.add ", "
  result.formatValue value.y, specifier
  result.add "]"

let v1 = Vec2[float32](x:1.0, y: 2.0)
let v2 = Vec2[int32](x:1, y: 1337)
doAssert fmt"v1: {v1:+08}  v2: {v2:>4}" == "v1: [+0000001, +0000002]  v2: [   1, 1337]"

# issue #7632

import genericstrformat

doAssert works(5) == "formatted  5"
doAssert fails0(6) == "formatted  6"
doAssert fails(7) == "formatted  7"
doAssert fails2[0](8) == "formatted  8"


# bug #11012

type
  Animal = object
    name, species: string
  AnimalRef = ref Animal

proc print_object(animalAddr: AnimalRef) =
  echo fmt"Received {animalAddr[]}"

print_object(AnimalRef(name: "Foo", species: "Bar"))
