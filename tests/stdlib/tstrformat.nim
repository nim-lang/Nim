discard """
  matrix: "--mm:refc; --mm:orc"
"""

import genericstrformat
import std/[strformat, strutils, times, tables, json]

import std/[assertions, formatfloat]
import std/objectdollar

proc main() =
  block: # issue #7632
    doAssert works(5) == "formatted  5"
    doAssert fails0(6) == "formatted  6"
    doAssert fails(7) == "formatted  7"
    doAssert fails2[0](8) == "formatted  8"

  block: # other tests
    type Obj = object

    proc `$`(o: Obj): string = "foobar"

    # for custom types, formatValue needs to be overloaded.
    template formatValue(result: var string; value: Obj; specifier: string) =
      result.formatValue($value, specifier)

    var o: Obj = default(Obj)
    doAssert fmt"{o}" == "foobar"
    doAssert fmt"{o:10}" == "foobar    "

    doAssert fmt"{o=}" == "o=foobar"
    doAssert fmt"{o=:10}" == "o=foobar    "

  block: # see issue #7933
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

  block: # see issue #7932
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

  block: # only add explicitly requested sign if value != -0.0 (neg zero)
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

  block: # seq format
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

  block: # custom format Value
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

  block: # bug #11012
    type
      Animal = object
        name, species: string
      AnimalRef = ref Animal

    proc print_object(animalAddr: AnimalRef): string =
      fmt"Received {animalAddr[]}"

    doAssert print_object(AnimalRef(name: "Foo", species: "Bar")) == """Received (name: "Foo", species: "Bar")"""

  block: # bug #11723
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

  block: # bug #12612
    proc my_proc() =
      const value = "value"
      const a = &"{value}"
      doAssert a == value

      const b = &"{value=}"
      doAssert b == "value=" & value

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

  block: # tests from the very own strformat documentation!
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

    let x = 3.14
    doAssert fmt"{(if x!=0: 1.0/x else: 0):.5}" == "0.31847"
    doAssert fmt"""{(block:
      var res: string = ""
      for i in 1..15:
        res.add (if i mod 15 == 0: "FizzBuzz"
          elif i mod 5 == 0: "Buzz"
          elif i mod 3 == 0: "Fizz"
          else: $i) & " "
      res)}""" == "1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz "

    doAssert fmt"""{ "\{(" & msg & ")\}" }""" == "{(hello)}"
    doAssert fmt"""{{({ msg })}}""" == "{(hello)}"
    doAssert fmt"""{ $(\{msg:1,"world":2\}) }""" == """[("hello", 1), ("world", 2)]"""
  block: # tests for debug format string
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

  block: # It is space sensitive.
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

  block:
    template check(actual, expected: string) =
      doAssert actual == expected

    # Basic tests
    let s = "string"
    check &"{0} {s}", "0 string"
    check &"{s[0..2].toUpperAscii}", "STR"
    check &"{-10:04}", "-010"
    check &"{-10:<04}", "-010"
    check &"{-10:>04}", "-010"
    check &"0x{10:02X}", "0x0A"

    check &"{10:#04X}", "0x0A"

    check &"""{"test":#>5}""", "#test"
    check &"""{"test":>5}""", " test"

    check &"""{"test":#^7}""", "#test##"

    check &"""{"test": <5}""", "test "
    check &"""{"test":<5}""", "test "
    check &"{1f:.3f}", "1.000"
    check &"Hello, {s}!", "Hello, string!"

    # Tests for identifiers without parenthesis
    check &"{s} works{s}", "string worksstring"
    check &"{s:>7}", " string"
    doAssert(not compiles(&"{s_works}")) # parsed as identifier `s_works`

    # Misc general tests
    check &"{{}}", "{}"
    check &"{0}%", "0%"
    check &"{0}%asdf", "0%asdf"
    check &("\n{\"\\n\"}\n"), "\n\n\n"
    check &"""{"abc"}s""", "abcs"

    # String tests
    check &"""{"abc"}""", "abc"
    check &"""{"abc":>4}""", " abc"
    check &"""{"abc":<4}""", "abc "
    check &"""{"":>4}""", "    "
    check &"""{"":<4}""", "    "

    # Int tests
    check &"{12345}", "12345"
    check &"{ - 12345}", "-12345"
    check &"{12345:6}", " 12345"
    check &"{12345:>6}", " 12345"
    check &"{12345:4}", "12345"
    check &"{12345:08}", "00012345"
    check &"{-12345:08}", "-0012345"
    check &"{0:0}", "0"
    check &"{0:02}", "00"
    check &"{-1:3}", " -1"
    check &"{-1:03}", "-01"
    check &"{10}", "10"
    check &"{16:#X}", "0x10"
    check &"{16:^#7X}", " 0x10  "
    check &"{16:^+#7X}", " +0x10 "

    # Hex tests
    check &"{0:x}", "0"
    check &"{-0:x}", "0"
    check &"{255:x}", "ff"
    check &"{255:X}", "FF"
    check &"{-255:x}", "-ff"
    check &"{-255:X}", "-FF"
    check &"{255:x} uNaffeCteD CaSe", "ff uNaffeCteD CaSe"
    check &"{255:X} uNaffeCteD CaSe", "FF uNaffeCteD CaSe"
    check &"{255:4x}", "  ff"
    check &"{255:04x}", "00ff"
    check &"{-255:4x}", " -ff"
    check &"{-255:04x}", "-0ff"

    # Float tests
    check &"{123.456}", "123.456"
    check &"{-123.456}", "-123.456"
    check &"{123.456:.3f}", "123.456"
    check &"{123.456:+.3f}", "+123.456"
    check &"{-123.456:+.3f}", "-123.456"
    check &"{-123.456:.3f}", "-123.456"
    check &"{123.456:1g}", "123.456"
    check &"{123.456:.1f}", "123.5"
    check &"{123.456:.0f}", "123."
    check &"{123.456:>9.3f}", "  123.456"
    check &"{123.456:9.3f}", "  123.456"
    check &"{123.456:>9.4f}", " 123.4560"
    check &"{123.456:>9.0f}", "     123."
    check &"{123.456:<9.4f}", "123.4560 "

    # Float (scientific) tests
    check &"{123.456:e}", "1.234560e+02"
    check &"{123.456:>13e}", " 1.234560e+02"
    check &"{123.456:<13e}", "1.234560e+02 "
    check &"{123.456:.1e}", "1.2e+02"
    check &"{123.456:.2e}", "1.23e+02"
    check &"{123.456:.3e}", "1.235e+02"

    # Note: times.format adheres to the format protocol. Test that this
    # works:
    when nimvm:
      discard
    else:
      var dt = dateTime(2000, mJan, 01, 00, 00, 00)
      check &"{dt:yyyy-MM-dd}", "2000-01-01"

      var tm = fromUnix(0)
      discard &"{tm}"

      var noww = now()
      check &"{noww}", $noww

    # Unicode string tests
    check &"""{"αβγ"}""", "αβγ"
    check &"""{"αβγ":>5}""", "  αβγ"
    check &"""{"αβγ":<5}""", "αβγ  "
    check &"""a{"a"}α{"α"}€{"€"}𐍈{"𐍈"}""", "aaαα€€𐍈𐍈"
    check &"""a{"a":2}α{"α":2}€{"€":2}𐍈{"𐍈":2}""", "aa αα €€ 𐍈𐍈 "
    # Invalid unicode sequences should be handled as plain strings.
    # Invalid examples taken from: https://stackoverflow.com/a/3886015/1804173
    let invalidUtf8 = [
      "\xc3\x28", "\xa0\xa1",
      "\xe2\x28\xa1", "\xe2\x82\x28",
      "\xf0\x28\x8c\xbc", "\xf0\x90\x28\xbc", "\xf0\x28\x8c\x28"
    ]
    for s in invalidUtf8:
      check &"{s:>5}", repeat(" ", 5-s.len) & s

    # bug #11089
    let flfoo: float = 1.0
    check &"{flfoo}", "1.0"

    # bug #11092
    check &"{high(int64)}", "9223372036854775807"
    check &"{low(int64)}", "-9223372036854775808"

    doAssert fmt"{'a'} {'b'}" == "a b"

  block: # test low(int64)
    doAssert &"{low(int64):-}" == "-9223372036854775808"
  block: #expressions plus formatting
    doAssert fmt"{if true\: 123.456 else\: 0=:>9.3f}" == "if true: 123.456 else: 0=  123.456"
    doAssert fmt"{(if true: 123.456 else: 0)=}" == "(if true: 123.456 else: 0)=123.456"
    doAssert fmt"{if true\: 123.456 else\: 0=:9.3f}" == "if true: 123.456 else: 0=  123.456"
    doAssert fmt"{(if true: 123.456 else: 0)=:9.4f}" == "(if true: 123.456 else: 0)= 123.4560"
    doAssert fmt"{(if true: 123.456 else: 0)=:>9.0f}" == "(if true: 123.456 else: 0)=     123."
    doAssert fmt"{if true\: 123.456 else\: 0=:<9.4f}" == "if true: 123.456 else: 0=123.4560 "

    doAssert fmt"""{(case true
      of false: 0.0
      of true: 123.456)=:e}""" == """(case true
      of false: 0.0
      of true: 123.456)=1.234560e+02"""

    doAssert fmt"""{block\:
      var res = 0.000123456
      for _ in 0..5\:
        res *= 10
      res=:>13e}""" == """block:
      var res = 0.000123456
      for _ in 0..5:
        res *= 10
      res= 1.234560e+02"""
    #side effects
    var x = 5
    doAssert fmt"{(x=7;123.456)=:13e}" == "(x=7;123.456)= 1.234560e+02"
    doAssert x==7

  block: # binary operators in interpolated expressions
    let n = 1
    doAssert &"{n-1}" == "0"
    doAssert fmt"{n-1}" == "0"

  block: #curly bracket expressions and tuples
    proc formatValue(result: var string; value:Table|bool|JsonNode; specifier:string) = result.add $value

    doAssert fmt"""{\{"a"\:1,"b"\:2\}.toTable() = }""" == """{"a":1,"b":2}.toTable() = {"a": 1, "b": 2}"""
    doAssert fmt"""{(\{3: (1,"hi",0.9),4: (4,"lo",1.1)\}).toTable()}""" == """{3: (1, "hi", 0.9), 4: (4, "lo", 1.1)}"""
    doAssert fmt"""{ (%* \{"name": "Isaac", "books": ["Robot Dreams"]\}) }""" == """{"name":"Isaac","books":["Robot Dreams"]}"""
    doAssert """%( \%\* {"name": "Isaac"})*""".fmt('%','*') == """{"name":"Isaac"}"""
  block: #parens in quotes that fool my syntax highlighter
    doAssert fmt"{(if true: ')' else: '(')}" == ")"
    doAssert fmt"{(if true: ']' else: ')')}" == "]"
    doAssert fmt"""{(if true: "\")\"" else: "\"(")}""" == """")""""
    doAssert &"""{(if true: "\")" else: "")}""" == "\")"
    doAssert &"{(if true: \"\\\")\" else: \"\")}" == "\")"
    doAssert fmt"""{(if true: "')" else: "")}""" == "')"
    doAssert fmt"""{(if true: "'" & "'" & ')' else: "")}""" == "'')"
    doAssert &"""{(if true: "'" & "'" & ')' else: "")}""" == "'')"
    doAssert &"{(if true: \"\'\" & \"'\" & ')' else: \"\")}" == "'')"
    doAssert fmt"""{(if true: "'" & ')' else: "")}""" == "')"

  block: # issue #20381
    var ss: seq[string] = @[]
    template myTemplate(s: string) =
      ss.add s
      ss.add s
    proc foo() =
      myTemplate fmt"hello"
    foo()
    doAssert ss == @["hello", "hello"]

  block:
    proc noraises() {.raises: [].} =
      const
        flt = 0.0
        str = "str"

      doAssert fmt"{flt} {str}" == "0.0 str"

    noraises()

  block:
    doAssert not compiles(fmt"{formatting errors detected at compile time")

  # ============================================================================
  # Python-compatible format specification tests
  # Tests for new features: = alignment, thousands separators, %, c type
  # ============================================================================

  block: # Thousands separator with comma
    # Python: f"{1234567890:,}" == "1,234,567,890"
    doAssert fmt"{1234567890:,}" == "1,234,567,890"
    doAssert fmt"{1234:,}" == "1,234"
    doAssert fmt"{123:,}" == "123"  # No separator needed
    doAssert fmt"{12:,}" == "12"
    doAssert fmt"{1:,}" == "1"
    doAssert fmt"{0:,}" == "0"
    # Negative numbers
    doAssert fmt"{-1234567:,}" == "-1,234,567"
    doAssert fmt"{-1234:,}" == "-1,234"
    # With width
    doAssert fmt"{1234:10,}" == "     1,234"
    doAssert fmt"{1234:010,}" == "00,001,234"
    # Python: format(1234, "08,d") == "0001,234"
    doAssert fmt"{1234:08,d}" == "0001,234"

  block: # Thousands separator with underscore
    # Python: f"{1234567890:_}" == "1_234_567_890"
    doAssert fmt"{1234567890:_}" == "1_234_567_890"
    doAssert fmt"{1234:_}" == "1_234"
    doAssert fmt"{123:_}" == "123"
    # Negative numbers
    doAssert fmt"{-1234567:_}" == "-1_234_567"
    # Binary with underscore (groups of 4)
    doAssert fmt"{255:_b}" == "1111_1111"
    doAssert fmt"{65535:_b}" == "1111_1111_1111_1111"
    doAssert fmt"{15:_b}" == "1111"  # No separator needed for 4 or fewer
    # Hex with underscore (groups of 4)
    doAssert fmt"{0xDEADBEEF:_x}" == "dead_beef"
    doAssert fmt"{0xFFFF:_x}" == "ffff"  # No separator for 4 or fewer
    doAssert fmt"{0xFFFFF:_x}" == "f_ffff"
    # Octal with underscore (groups of 4)
    doAssert fmt"{0o7654321:_o}" == "765_4321"

  block: # Thousands separator with floats
    # Python: f"{1234567890:,.2f}" == "1,234,567,890.00"
    doAssert fmt"{1234567890.0:,.2f}" == "1,234,567,890.00"
    doAssert fmt"{1234.5678:,.2f}" == "1,234.57"
    doAssert fmt"{1234567.89:_.2f}" == "1_234_567.89"
    # Negative floats
    doAssert fmt"{-1234567.89:,.2f}" == "-1,234,567.89"

  block: # = alignment (sign-aware padding)
    # Python: f"{-42:=10}" == "-        42" (spaces after sign)
    # But with 0 prefix: f"{-42:0=10}" == "-000000042"
    doAssert fmt"{-42:0=10}" == "-000000042"
    doAssert fmt"{42:0=+10}" == "+000000042"
    doAssert fmt"{42:0= 10}" == " 000000042"
    # With custom fill character
    doAssert fmt"{-42:*=10}" == "-*******42"
    doAssert fmt"{42:*=+10}" == "+*******42"
    # Floats with = alignment
    doAssert fmt"{-3.14:0=10}" == "-000003.14"
    doAssert fmt"{3.14:0=+10}" == "+000003.14"
    doAssert fmt"{-3.14:*=10}" == "-*****3.14"

  block: # Percentage formatting
    # Python: f"{0.25:.2%}" == "25.00%"
    doAssert fmt"{0.25:.2%}" == "25.00%"
    doAssert fmt"{0.5:%}" == "50.000000%"
    doAssert fmt"{1.0:.0%}" == "100.%"
    doAssert fmt"{0.125:.1%}" == "12.5%"
    # Negative percentages
    doAssert fmt"{-0.25:.2%}" == "-25.00%"
    # With width and alignment
    doAssert fmt"{0.25:>10.2%}" == "    25.00%"
    doAssert fmt"{0.25:<10.2%}" == "25.00%    "
    doAssert fmt"{0.25:^10.2%}" == "  25.00%  "
    # Zero padding
    doAssert fmt"{0.05:010.2%}" == "000005.00%"

  block: # Character type (c)
    # Python: f"{65:c}" == "A"
    doAssert fmt"{65:c}" == "A"
    doAssert fmt"{97:c}" == "a"
    doAssert fmt"{48:c}" == "0"
    doAssert fmt"{32:c}" == " "
    # Unicode characters
    doAssert fmt"{0x03B1:c}" == "α"  # Greek alpha
    doAssert fmt"{0x1F600:c}" == "😀"  # Emoji
    # With width and alignment
    doAssert fmt"{65:>5c}" == "    A"
    doAssert fmt"{65:<5c}" == "A    "
    doAssert fmt"{65:^5c}" == "  A  "
    doAssert fmt"{65:*>5c}" == "****A"

  block: # Combined features
    # Width + thousands separator + precision
    # Python: f"{1234567890:020,.2f}" == "0,001,234,567,890.00"
    doAssert fmt"{1234567890.0:020,.2f}" == "0,001,234,567,890.00"
    # Sign + width + separator
    doAssert fmt"{1234567:+,}" == "+1,234,567"
    doAssert fmt"{-1234567:+,}" == "-1,234,567"
    # Alternate form + separator (hex)
    doAssert fmt"{0xDEADBEEF:#_x}" == "0xdead_beef"
    doAssert fmt"{0xDEADBEEF:#_X}" == "0xDEAD_BEEF"

  block: # Edge cases
    # Zero with thousands separator
    doAssert fmt"{0:,}" == "0"
    doAssert fmt"{0:_}" == "0"
    # Very large numbers
    doAssert fmt"{999999999999:,}" == "999,999,999,999"
    # Percentage of zero
    doAssert fmt"{0.0:.2%}" == "0.00%"
    # Character edge cases
    doAssert fmt"{0:c}" == "\x00"  # Null character

static: main()
main()
