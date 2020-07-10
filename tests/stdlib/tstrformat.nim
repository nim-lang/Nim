discard """
action: "run"
output: '''Received (name: "Foo", species: "Bar")'''
"""

# issue #7632

import genericstrformat
import strutils


doAssert works(5) == "formatted  5"
doAssert fails0(6) == "formatted  6"
doAssert fails(7) == "formatted  7"
doAssert fails2[0](8) == "formatted  8"

# other tests

import strformat

type Obj = object

proc `$`(o: Obj): string = "foobar"

# for custom types, formatValue needs to be overloaded.
template formatValue(result: var string; value: Obj; specifier: string) =
  result.formatValue($value, specifier)

var o: Obj
doAssert fmt"{o}" == "foobar"
doAssert fmt"{o:10}" == "foobar    "

doAssert fmt"{o=}" == "o=foobar"
doAssert fmt"{o=:10}" == "o=foobar    "


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

doAssert fmt">7.1 :: {str=:>7.1}" == ">7.1 :: str=      a"
doAssert fmt">7.2 :: {str=:>7.2}" == ">7.2 :: str=     ab"
doAssert fmt">7.3 :: {str=:>7.3}" == ">7.3 :: str=    abc"
doAssert fmt">7.9 :: {str=:>7.9}" == ">7.9 :: str=    abc"
doAssert fmt">7.0 :: {str=:>7.0}" == ">7.0 :: str=       "
doAssert fmt" 7.1 :: {str=:7.1}" == " 7.1 :: str=a      "
doAssert fmt" 7.2 :: {str=:7.2}" == " 7.2 :: str=ab     "
doAssert fmt" 7.3 :: {str=:7.3}" == " 7.3 :: str=abc    "
doAssert fmt" 7.9 :: {str=:7.9}" == " 7.9 :: str=abc    "
doAssert fmt" 7.0 :: {str=:7.0}" == " 7.0 :: str=       "
doAssert fmt"^7.1 :: {str=:^7.1}" == "^7.1 :: str=   a   "
doAssert fmt"^7.2 :: {str=:^7.2}" == "^7.2 :: str=  ab   "
doAssert fmt"^7.3 :: {str=:^7.3}" == "^7.3 :: str=  abc  "
doAssert fmt"^7.9 :: {str=:^7.9}" == "^7.9 :: str=  abc  "
doAssert fmt"^7.0 :: {str=:^7.0}" == "^7.0 :: str=       "
str = "äöüe\u0309\u0319o\u0307\u0359"
doAssert fmt"^7.1 :: {str:^7.1}" == "^7.1 ::    ä   "
doAssert fmt"^7.2 :: {str:^7.2}" == "^7.2 ::   äö   "
doAssert fmt"^7.3 :: {str:^7.3}" == "^7.3 ::   äöü  "
doAssert fmt"^7.0 :: {str:^7.0}" == "^7.0 ::        "

doAssert fmt"^7.1 :: {str=:^7.1}" == "^7.1 :: str=   ä   "
doAssert fmt"^7.2 :: {str=:^7.2}" == "^7.2 :: str=  äö   "
doAssert fmt"^7.3 :: {str=:^7.3}" == "^7.3 :: str=  äöü  "
doAssert fmt"^7.0 :: {str=:^7.0}" == "^7.0 :: str=       "
# this is actually wrong, but the unicode module has no support for graphemes
doAssert fmt"^7.4 :: {str:^7.4}" == "^7.4 ::  äöüe  "
doAssert fmt"^7.9 :: {str:^7.9}" == "^7.9 :: äöüe\u0309\u0319o\u0307\u0359"

doAssert fmt"^7.4 :: {str=:^7.4}" == "^7.4 :: str= äöüe  "
doAssert fmt"^7.9 :: {str=:^7.9}" == "^7.9 :: str=äöüe\u0309\u0319o\u0307\u0359"

# see issue #7932
doAssert fmt"{15:08}" == "00000015" # int, works
doAssert fmt"{1.5:08}" == "000001.5" # float, works
doAssert fmt"{1.5:0>8}" == "000001.5" # workaround using fill char works for positive floats
doAssert fmt"{-1.5:0>8}" == "0000-1.5" # even that does not work for negative floats
doAssert fmt"{-1.5:08}" == "-00001.5" # works
doAssert fmt"{1.5:+08}" == "+00001.5" # works
doAssert fmt"{1.5: 08}" == " 00001.5" # works

doAssert fmt"{15=:08}" == "15=00000015" # int, works
doAssert fmt"{1.5=:08}" == "1.5=000001.5" # float, works
doAssert fmt"{1.5=:0>8}" == "1.5=000001.5" # workaround using fill char works for positive floats
doAssert fmt"{-1.5=:0>8}" == "-1.5=0000-1.5" # even that does not work for negative floats
doAssert fmt"{-1.5=:08}" == "-1.5=-00001.5" # works
doAssert fmt"{1.5=:+08}" == "1.5=+00001.5" # works
doAssert fmt"{1.5=: 08}" == "1.5= 00001.5" # works

# only add explicitly requested sign if value != -0.0 (neg zero)
doAssert fmt"{-0.0:g}" == "-0"
doAssert fmt"{-0.0:+g}" == "-0"
doAssert fmt"{-0.0: g}" == "-0"
doAssert fmt"{0.0:g}" == "0"
doAssert fmt"{0.0:+g}" == "+0"
doAssert fmt"{0.0: g}" == " 0"

doAssert fmt"{-0.0=:g}" == "-0.0=-0"
doAssert fmt"{-0.0=:+g}" == "-0.0=-0"
doAssert fmt"{-0.0=: g}" == "-0.0=-0"
doAssert fmt"{0.0=:g}" == "0.0=0"
doAssert fmt"{0.0=:+g}" == "0.0=+0"
doAssert fmt"{0.0=: g}" == "0.0= 0"

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

doAssert fmt"data1: {data1=:8} #" == "data1: data1=[       1,    10000, 10000000] #"
doAssert fmt"data2: {data2=:8} =" == "data2: data2=[10000000,      100,        1] ="

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
doAssert fmt"v1: {v1=:+08}  v2: {v2=:>4}" == "v1: v1=[+0000001, +0000002]  v2: v2=[   1, 1337]"

# bug #11012

type
  Animal = object
    name, species: string
  AnimalRef = ref Animal

proc print_object(animalAddr: AnimalRef) =
  echo fmt"Received {animalAddr[]}"

print_object(AnimalRef(name: "Foo", species: "Bar"))

# bug #11723

let pos: Positive = 64
doAssert fmt"{pos:3}" == " 64"
doAssert fmt"{pos:3b}" == "1000000"
doAssert fmt"{pos:3d}" == " 64"
doAssert fmt"{pos:3o}" == "100"
doAssert fmt"{pos:3x}" == " 40"
doAssert fmt"{pos:3X}" == " 40"

doAssert fmt"{pos=:3}" == "pos= 64"
doAssert fmt"{pos=:3b}" == "pos=1000000"
doAssert fmt"{pos=:3d}" == "pos= 64"
doAssert fmt"{pos=:3o}" == "pos=100"
doAssert fmt"{pos=:3x}" == "pos= 40"
doAssert fmt"{pos=:3X}" == "pos= 40"


let nat: Natural = 64
doAssert fmt"{nat:3}" == " 64"
doAssert fmt"{nat:3b}" == "1000000"
doAssert fmt"{nat:3d}" == " 64"
doAssert fmt"{nat:3o}" == "100"
doAssert fmt"{nat:3x}" == " 40"
doAssert fmt"{nat:3X}" == " 40"

doAssert fmt"{nat=:3}" == "nat= 64"
doAssert fmt"{nat=:3b}" == "nat=1000000"
doAssert fmt"{nat=:3d}" == "nat= 64"
doAssert fmt"{nat=:3o}" == "nat=100"
doAssert fmt"{nat=:3x}" == "nat= 40"
doAssert fmt"{nat=:3X}" == "nat= 40"

# bug #12612
proc my_proc =
  const value = "value"
  const a = &"{value}"
  assert a == value

  const b = &"{value=}"
  assert b == "value=" & value

my_proc()

block:
  template fmt(pattern: string; openCloseChar: char): untyped =
    fmt(pattern, openCloseChar, openCloseChar)

  let
    testInt = 123
    testStr = "foobar"
    testFlt = 3.141592
  doAssert ">><<".fmt('<', '>') == "><"
  doAssert " >> << ".fmt('<', '>') == " > < "
  doAssert "<<>>".fmt('<', '>') == "<>"
  doAssert " << >> ".fmt('<', '>') == " < > "
  doAssert "''".fmt('\'') == "'"
  doAssert "''''".fmt('\'') == "''"
  doAssert "'' ''".fmt('\'') == "' '"
  doAssert "<testInt>".fmt('<', '>') == "123"
  doAssert "<testInt>".fmt('<', '>') == "123"
  doAssert "'testFlt:1.2f'".fmt('\'') == "3.14"
  doAssert "<testInt><testStr>".fmt('<', '>') == "123foobar"
  doAssert """ ""{"123+123"}"" """.fmt('"') == " \"{246}\" "
  doAssert "(((testFlt:1.2f)))((111))".fmt('(', ')') == "(3.14)(111)"
  doAssert """(()"foo" & "bar"())""".fmt(')', '(') == "(foobar)"
  doAssert "{}abc`testStr' `testFlt:1.2f' `1+1' ``".fmt('`', '\'') == "{}abcfoobar 3.14 2 `"
  doAssert """x = '"foo" & "bar"'
              y = '123 + 111'
              z = '3 in {2..7}'
           """.fmt('\'') ==
           """x = foobar
              y = 234
              z = true
           """


# tests from the very own strformat documentation!

let msg = "hello"
doAssert fmt"{msg}\n" == "hello\\n"

doAssert &"{msg}\n" == "hello\n"

doAssert fmt"{msg}{'\n'}" == "hello\n"
doAssert fmt("{msg}\n") == "hello\n"
doAssert "{msg}\n".fmt == "hello\n"

doAssert fmt"{msg=}\n" == "msg=hello\\n"

doAssert &"{msg=}\n" == "msg=hello\n"

doAssert fmt"{msg=}{'\n'}" == "msg=hello\n"
doAssert fmt("{msg=}\n") == "msg=hello\n"
doAssert "{msg=}\n".fmt == "msg=hello\n"

doAssert &"""{"abc":>4}""" == " abc"
doAssert &"""{"abc":<4}""" == "abc "

doAssert fmt"{-12345:08}" == "-0012345"
doAssert fmt"{-1:3}" == " -1"
doAssert fmt"{-1:03}" == "-01"
doAssert fmt"{16:#X}" == "0x10"

doAssert fmt"{123.456}" == "123.456"
doAssert fmt"{123.456:>9.3f}" == "  123.456"
doAssert fmt"{123.456:9.3f}" == "  123.456"
doAssert fmt"{123.456:9.4f}" == " 123.4560"
doAssert fmt"{123.456:>9.0f}" == "     123."
doAssert fmt"{123.456:<9.4f}" == "123.4560 "

doAssert fmt"{123.456:e}" == "1.234560e+02"
doAssert fmt"{123.456:>13e}" == " 1.234560e+02"
doAssert fmt"{123.456:13e}" == " 1.234560e+02"


doAssert &"""{"abc"=:>4}""" == "\"abc\"= abc"
doAssert &"""{"abc"=:<4}""" == "\"abc\"=abc "

doAssert fmt"{-12345=:08}" == "-12345=-0012345"
doAssert fmt"{-1=:3}" == "-1= -1"
doAssert fmt"{-1=:03}" == "-1=-01"
doAssert fmt"{16=:#X}" == "16=0x10"

doAssert fmt"{123.456=}" == "123.456=123.456"
doAssert fmt"{123.456=:>9.3f}" == "123.456=  123.456"
doAssert fmt"{123.456=:9.3f}" == "123.456=  123.456"
doAssert fmt"{123.456=:9.4f}" == "123.456= 123.4560"
doAssert fmt"{123.456=:>9.0f}" == "123.456=     123."
doAssert fmt"{123.456=:<9.4f}" == "123.456=123.4560 "

doAssert fmt"{123.456=:e}" == "123.456=1.234560e+02"
doAssert fmt"{123.456=:>13e}" == "123.456= 1.234560e+02"
doAssert fmt"{123.456=:13e}" == "123.456= 1.234560e+02"

## tests for debug format string
block:
  var name = "hello"
  let age = 21
  const hobby = "swim"
  doAssert fmt"{age*9 + 16=}" == "age*9 + 16=205"
  doAssert &"name: {name    =}\nage: {  age  =: >7}\nhobby: {   hobby=  : 8}" == 
        "name: name    =hello\nage:   age  =     21\nhobby:    hobby=  swim    "
  doAssert fmt"{age  ==  12}" == "false"
  doAssert fmt"{name.toUpperAscii() = }" == "name.toUpperAscii() = HELLO"
  doAssert fmt"{name.toUpperAscii( ) =  }" == "name.toUpperAscii( ) =  HELLO"
  doAssert fmt"{  toUpperAscii(  s  =  name  )  =   }" == "  toUpperAscii(  s  =  name  )  =   HELLO"
  doAssert fmt"{  strutils.toUpperAscii(  s  =  name  )  =   }" == "  strutils.toUpperAscii(  s  =  name  )  =   HELLO"
  doAssert fmt"{age==12}" == "false"
  doAssert fmt"{age!= 12}" == "true"
  doAssert fmt"{age  <=  12}" == "false"
  for i in 1 .. 10:
    doAssert fmt"{age.float =: .2f}" == "age.float = 21.00"
  doAssert fmt"{age.float() =:.3f}" == "age.float() =21.000"
  doAssert fmt"{float age=  :.3f}" == "float age=  21.000"
  doAssert fmt"{12 == int(`!=`(age, 12))}" == "false"
  doAssert fmt"{0==1}" == "false"


# It is space sensitive.
block:
  let x = "12"
  doAssert fmt"{x=:}" == "x=12"
  doAssert fmt"{x=}" == "x=12"
  doAssert fmt"{x =:}" == "x =12"
  doAssert fmt"{x =}" == "x =12"
  doAssert fmt"{x= :}" == "x= 12"
  doAssert fmt"{x= }" == "x= 12"
  doAssert fmt"{x = :}" == "x = 12"
  doAssert fmt"{x = }" == "x = 12"
  doAssert fmt"{x   =  :}" == "x   =  12"
  doAssert fmt"{x   =  }" == "x   =  12"

block:
  let x = "hello"
  doAssert fmt"{x=}" == "x=hello" 
  doAssert fmt"{x =}" == "x =hello"


  let y = 3.1415926
  doAssert fmt"{y=:.2f}" == fmt"y={y:.2f}"
  doAssert fmt"{y=}" == fmt"y={y}"
  doAssert fmt"{y = : <8}" == fmt"y = 3.14159 "

  proc hello(a: string, b: float): int = 12
  template foo(a: string, b: float): int = 18

  doAssert fmt"{hello(x, y)=}" == "hello(x, y)=12"
  doAssert fmt"{hello(x, y) =}" == "hello(x, y) =12"
  doAssert fmt"{hello(x, y)= }" == "hello(x, y)= 12"
  doAssert fmt"{hello(x, y) = }" == "hello(x, y) = 12"

  doAssert fmt"{hello x, y=}" == "hello x, y=12"
  doAssert fmt"{hello x, y =}" == "hello x, y =12"
  doAssert fmt"{hello x, y= }" == "hello x, y= 12"
  doAssert fmt"{hello x, y = }" == "hello x, y = 12"

  doAssert fmt"{x.hello(y)=}" == "x.hello(y)=12"
  doAssert fmt"{x.hello(y) =}" == "x.hello(y) =12"
  doAssert fmt"{x.hello(y)= }" == "x.hello(y)= 12"
  doAssert fmt"{x.hello(y) = }" == "x.hello(y) = 12"

  doAssert fmt"{foo(x, y)=}" == "foo(x, y)=18"
  doAssert fmt"{foo(x, y) =}" == "foo(x, y) =18"
  doAssert fmt"{foo(x, y)= }" == "foo(x, y)= 18"
  doAssert fmt"{foo(x, y) = }" == "foo(x, y) = 18"

  doAssert fmt"{x.foo(y)=}" == "x.foo(y)=18"
  doAssert fmt"{x.foo(y) =}" == "x.foo(y) =18"
  doAssert fmt"{x.foo(y)= }" == "x.foo(y)= 18"
  doAssert fmt"{x.foo(y) = }" == "x.foo(y) = 18"
