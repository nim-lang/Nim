discard """
  targets: "c js"
"""

import std/setutils

type 
  Colors = enum
    red, green = 5, blue = 10
  Bar = enum
    bar0 = -1, bar1, bar2

template main =
  block: # toSet
    doAssert "abcbb".toSet == {'a', 'b', 'c'}
    doAssert toSet([10u8, 12, 13]) == {10u8, 12, 13}
    doAssert toSet(0u16..30) == {0u16..30}
    type A = distinct char
    doAssert [A('x')].toSet == {A('x')}

  block: # fullSet
    doAssert fullSet(Colors) == {red, green, blue}
    doAssert fullSet(char) == {0.chr..255.chr}
    doAssert fullSet(Bar) == {bar0, bar1, bar2}
    doAssert fullSet(bool) == {true, false}

  block: # complement
    doAssert {red, blue}.complement == {green}
    doAssert (complement {red, green, blue}).card == 0
    doAssert (complement {false}) == {true}
    doAssert {bar0}.complement == {bar1, bar2}
    doAssert {range[0..10](0), 1, 2, 3}.complement == {range[0..10](4), 5, 6, 7, 8, 9, 10}
    doAssert {'0'..'9'}.complement == {0.char..255.char} - {'0'..'9'}

  block: # `[]=`
    type A = enum
      a0, a1, a2, a3
    var s = {a0, a3}
    s[a0] = false
    s[a1] = false
    doAssert s == {a3}
    s[a2] = true
    s[a3] = true
    doAssert s == {a2, a3}

main()
static: main()
