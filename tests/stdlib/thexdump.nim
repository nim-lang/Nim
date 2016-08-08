discard """
  output: '''0000: 61 62 63 0A .. .. .. .. .. .. .. .. .. .. .. ..  'abc.'
0000: 61 62 63 0A  'abc.'
0000: 61 62 63 0A .. .. .. .. .. .. .. .. .. .. .. ..  'abc.'
0000: 00 01 02 03 FF .. .. .. .. .. .. .. .. .. .. ..  '.....'
30 31 32 33 34 35 36
30 31 32 33 34 35 36  '0123456'
61 62 63 0A  'abc.'
00: 30  '0'
01: 31  '1'
02: 32  '2'
03: 33  '3'
04: 34  '4'
05: 35  '5'
06: 36  '6'
00: 30 31  '01'
02: 32 33  '23'
04: 34 35  '45'
06: 36 ..  '6'
00: 30 31 32 33  '0123'
04: 34 35 36 ..  '456'
00: 30 31 32 33 34 35  '012345'
06: 36 .. .. .. .. ..  '6'
30 31 32 33  '0123'
34 35 36 ..  '456'
00: 30 31
02: 32 33
04: 34 35
06: 36
00: 30 31
02: 32 33
04: 34 35
06: 36
00: 30 31 32 33
04: 34 35 36
00: 30 31 32 33 34 35
06: 36
00000000: 30 31 32 33 34 35 36 37 38 39 30 0D 00 41 42 43  '01234567890..ABC'
00000010: 44 65 66 67 C3 B6 C3 A4 C3 BC 2A .. .. .. .. ..  'Defg......*'
00000000: 30 31 32 33 34 35 36 37 38 39 30 0D 00 41 42 43
00000010: 44 65 66 67 C3 B6 C3 A4 C3 BC 2A
'''
"""

import strutils

echo hexDump("abc\l")
let s1: seq[char] = @['a','b','c','\l']
echo hexDump(s1, cols = 0)
let s2: array[4, char] = ['a','b','c','\l']
echo hexDump(s2)

type hexCodes = enum
  zero
  one
  two
  three
  efef = 255

let s3 = @[zero, one, two, three, efef]
echo hexDump(s3)

echo hexDump("0123456",false,0,0)
echo hexDump("0123456",true,0,0)
echo hexDump("abc\l",true,0,0)
echo hexDump("0123456",true,1,1)
echo hexDump("0123456",true,2,1)
echo hexDump("0123456",true,4,1)
echo hexDump("0123456",true,6,1)
echo hexDump("0123456",true,4,0)
echo hexDump("0123456",false,2,1)
echo hexDump("0123456",false,2,1)
echo hexDump("0123456",false,4,1)
echo hexDump("0123456",false,6,1)
echo hexDump("01234567890\r\0ABCDefgöäü*", offs = 4)
echo hexDump("01234567890\r\0ABCDefgöäü*",false, offs = 4)
