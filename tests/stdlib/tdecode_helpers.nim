import std/private/decode_helpers


block:
  var i = 0
  let c = decodePercent("%t9", i)
  doAssert (i, c) == (0, '%')

block:
  var i = 0
  let c = decodePercent("19", i)
  doAssert (i, c) == (0, '%')

block:
  var i = 0
  let c = decodePercent("%19", i)
  doAssert (i, c) == (2, '\x19')

block:
  var i = 0
  let c = decodePercent("%A9", i)
  doAssert (i, c) == (2, '\xA9')

block:
  var i = 0
  let c = decodePercent("%Aa", i)
  doAssert (i, c) == (2, '\xAA')
