import macros

discard """
nimout: '''
8 9 17
239 255
61439 65534 65535
4026531839 4294967294
17293822569102704639
18446744073709551614
18446744073709551615
127
32767
2147483647
9223372036854775807
0
128
4294967287'''
"""

#bug #2514

macro foo() =
  var x = 8'u8
  var y = 9'u16
  var z = 17'u32

  echo x," ", y," ", z

  var a = 0xEF'u8
  var aa = 0xFF'u8
  echo a, " ", aa

  var b = 0xEFFF'u16
  var bb = 0xFFFE'u16
  var bbb = 0xFFFF'u16
  echo b, " ", bb, " ", bbb

  var c = 0xEFFFFFFF'u32
  var cc = 0xFFFFFFFE'u32
  echo c, " ", cc

  var d = 0xEFFFFFFFFFFFFFFF'u64
  echo d

  var f = 0xFFFFFFFFFFFFFFFE'u64
  echo f

  var g = 0xFFFFFFFFFFFFFFFF'u64
  echo g

  var xx = 0x7F'u8 and 0xFF
  echo xx

  var yy = 0x7FFF'u16
  echo yy

  var zz = 0x7FFFFFFF'u32
  echo zz

macro foo2() =
  var xx = 0x7FFFFFFFFFFFFFFF
  echo xx

  var yy = 0
  echo yy

  var zz = 0x80'u8
  echo zz

  var ww = -9
  var vv = cast[uint](ww)
  var kk = cast[uint32](vv)
  echo kk

foo()
foo2()
