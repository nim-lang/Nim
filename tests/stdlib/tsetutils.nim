discard """
  targets: "c js"
"""
import std/setutils

template main =
  block toSetTest:
    doAssert "abcbb".toSet == {'a', 'b', 'c'}
    doAssert toSet([10u8, 12, 13]) == {10u8, 12, 13}
    doAssert toSet(0u16..30) == {0u16..30}
    type A = distinct char
    doAssert [A('x')].toSet == {A('x')}
  block fullSetTest:
    type Colors{.inject.} = enum
      red, green = 5, blue = 10
    doAssert {true, false} == fullSet(bool)
    doAssert {red, green, blue} == fullSet(Colors)
    doAssert {0.chr..255.chr} == fullSet(char)
  block notTest:
    type Colors{.inject.} = enum
      red, green = 5, blue = 10
    doAssert {red, blue}.not == {green}
    doAssert (not {red, green, blue}).card == 0
    doAssert {range[0..10](0), 1, 2, 3}.not == {range[0..10](4), 5, 6, 7, 8, 9, 10}
    doAssert {'0'..'9'}.not == {0.char..255.char} - {'0'..'9'}
    doAssert (not {false}) == {true}
main()
static: main()