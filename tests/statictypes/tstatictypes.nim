discard """
nimout: '''
staticAlialProc instantiated with 4
staticAlialProc instantiated with 6
'''
"""

import macros

proc plus(a, b: int): int = a + b

when true:
  type
    StaticTypeAlias = static[int]

  proc staticAliasProc(s: StaticTypeAlias) =
    static: echo "staticAlialProc instantiated with ", s + 1
    echo s

  staticAliasProc 1+2
  staticAliasProc 3
  staticAliasProc 5

when true:
  type
    ArrayWrapper1[S: static int] = object
      data: array[S + 1, int]

    ArrayWrapper2[S: static[int]] = object
      data: array[S.plus(2), int]

    ArrayWrapper3[S: static[(int, string)]] = object
      data: array[S[0], int]

  var aw1: ArrayWrapper1[5]
  var aw2: ArrayWrapper2[5]
  var aw3: ArrayWrapper3[(10, "str")]
  
  static:
    assert aw1.data.high == 5
    assert aw2.data.high == 6
    assert aw3.data.high == 9

