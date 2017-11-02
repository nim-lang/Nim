discard """
  output:""
"""

doAssert "@[23, 45]" == $(@[23, 45])
doAssert "[32, 45]" == $([32, 45])
doAssert "@[, foo, bar]" == $(@["", "foo", "bar"])
doAssert "[, foo, bar]" ==  $(["", "foo", "bar"])

# bug #2395
let alphaSet: set[char] = {'a'..'c'}
doAssert "{a, b, c}" == $alphaSet
doAssert "2.3242" == $(2.3242)
doAssert "2.982" == $(2.982)
doAssert "123912.1" == $(123912.1)
doAssert "123912.1823" == $(123912.1823)
doAssert "5.0" == $(5.0)
doAssert "1e+100" == $(1e100)
doAssert "inf" == $(1e1000000)
doAssert "-inf" == $(-1e1000000)
doAssert "nan" == $(0.0/0.0)

# nil tests
# maybe a bit inconsistent in types
var x: seq[string]
doAssert "nil" == $(x)

var y: string = nil
doAssert nil == $(y)

type
  Foo = object
    a: int
    b: string

var foo1: Foo

# nil string should be an some point in time equal to the empty string
doAssert(($foo1)[0..9] == "(a: 0, b: ")

const
  data = @['a','b', '\0', 'c','d']
  dataStr = $data

# ensure same result when on VM or when at program execution
doAssert dataStr == $data

import strutils
# array test

let arr = ['H','e','l','l','o',' ','W','o','r','l','d','!','\0']
doAssert $arr == "[H, e, l, l, o,  , W, o, r, l, d, !, \0]"
doAssert $cstring(unsafeAddr arr) == "Hello World!"
