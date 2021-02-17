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
    doAssert fullSet(bool) == {true, false}
    doAssert fullSet(Colors) == {red, green, blue}
    doAssert fullSet(char) == {0.chr..255.chr}
    doAssert fullSet(Bar) == {bar0, bar1, bar2}

  block: # not
    doAssert {red, blue}.not == {green}
    doAssert (not {red, green, blue}).card == 0
    doAssert {bar0}.not == {bar1, bar2}
    doAssert {range[0..10](0), 1, 2, 3}.not == {range[0..10](4), 5, 6, 7, 8, 9, 10}
    doAssert {'0'..'9'}.not == {0.char..255.char} - {'0'..'9'}
    doAssert (not {false}) == {true}

main()
static: main()