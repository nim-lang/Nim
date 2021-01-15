discard """
  targets: "c js"
"""
import std/setutils

template main =
  doAssert "abcbb".toSet == {'a', 'b', 'c'}
  doAssert toSet([10u8, 12, 13]) == {10u8, 12, 13}
  doAssert toSet(0u16..30) == {0u16..30}
  type A = distinct char
  doAssert [A('x')].toSet == {A('x')}
  
main()
static: main()