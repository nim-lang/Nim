data = [
    ('addInt',      'addInt($1, $2)',     '($1 + $2)'),
    ('subInt',      'subInt($1, $2)',     '($1 - $2)'), 
    ('mulInt',      'mulInt($1, $2)',     '($1 * $2)'),
    ('divInt',      'divInt($1, $2)',     'Math.floor($1 / $2)'),
    ('modInt',      'modInt($1, $2)',     '($1 % $2)'),
    ('addInt64',    'addInt64($1, $2)',   '($1 + $2)'),
    ('subInt64',    'subInt64($1, $2)',   '($1 - $2)'),
    ('mulInt64',    'mulInt64($1, $2)',   '($1 * $2)'),
    ('divInt64',    'divInt64($1, $2)',   'Math.floor($1 / $2)'),
    ('modInt64',    'modInt64($1, $2)',   '($1 % $2)'),
    ('',            '($1 >>> $2)',        '($1 >>> $2)'), # ShrI
    ('',            '($1 << $2)',         '($1 << $2)'), # ShlI
    ('',            '($1 & $2)',          '($1 & $2)'), # BitandI
    ('',            '($1 | $2)',          '($1 | $2)'), # BitorI
    ('',            '($1 ^ $2)',          '($1 ^ $2)'),# BitxorI
    ('nimMin',      'nimMin($1, $2)',     'nimMin($1, $2)'), # MinI
    ('nimMax',      'nimMax($1, $2)',     'nimMax($1, $2)'), # MaxI
    ('',            '($1 >>> $2)',        '($1 >>> $2)'), # ShrI64
    ('',            '($1 << $2)',         '($1 << $2)'), # ShlI64
    ('',            '($1 & $2)',          '($1 & $2)'), # BitandI64
    ('',            '($1 | $2)',          '($1 | $2)'), # BitorI64
    ('',            '($1 ^ $2)',          '($1 ^ $2)'), # BitxorI64
    ('nimMin',      'nimMin($1, $2)',     'nimMin($1, $2)'), # MinI64
    ('nimMax',      'nimMax($1, $2)',     'nimMax($1, $2)'), # MaxI64
    ('',            '($1 + $2)',          '($1 + $2)'), # AddF64
    ('',            '($1 - $2)',          '($1 - $2)'), # SubF64
    ('',            '($1 * $2)',          '($1 * $2)'), # MulF64
    ('',            '($1 / $2)',          '($1 / $2)'), # DivF64
    ('nimMin',      'nimMin($1, $2)',     'nimMin($1, $2)'), # MinF64
    ('nimMax',      'nimMax($1, $2)',     'nimMax($1, $2)'), # MaxF64
    ('AddU',        'AddU($1, $2)',       'AddU($1, $2)'), # AddU
    ('SubU',        'SubU($1, $2)',       'SubU($1, $2)'), # SubU
    ('MulU',        'MulU($1, $2)',       'MulU($1, $2)'), # MulU
    ('DivU',        'DivU($1, $2)',       'DivU($1, $2)'), # DivU
    ('ModU',        'ModU($1, $2)',       'ModU($1, $2)'), # ModU
    ('AddU64',      'AddU64($1, $2)',     'AddU64($1, $2)'), # AddU64
    ('SubU64',      'SubU64($1, $2)',     'SubU64($1, $2)'), # SubU64
    ('MulU64',      'MulU64($1, $2)',     'MulU64($1, $2)'), # MulU64
    ('DivU64',      'DivU64($1, $2)',     'DivU64($1, $2)'), # DivU64
    ('ModU64',      'ModU64($1, $2)',     'ModU64($1, $2)'), # ModU64
    ('',            '($1 == $2)',         '($1 == $2)'), # EqI
    ('',            '($1 <= $2)',         '($1 <= $2)'), # LeI
    ('',            '($1 < $2)',          '($1 < $2)'), # LtI
    ('',            '($1 == $2)',         '($1 == $2)'), # EqI64
    ('',            '($1 <= $2)',         '($1 <= $2)'), # LeI64
    ('',            '($1 < $2)',          '($1 < $2)'), # LtI64
    ('',            '($1 == $2)',         '($1 == $2)'), # EqF64
    ('',            '($1 <= $2)',         '($1 <= $2)'), # LeF64
    ('',            '($1 < $2)',          '($1 < $2)'), # LtF64

    ('LeU',         'LeU($1, $2)',        'LeU($1, $2)'), # LeU
    ('LtU',         'LtU($1, $2)',        'LtU($1, $2)'), # LtU
    ('LeU64',       'LeU64($1, $2)',      'LeU64($1, $2)'), # LeU64
    ('LtU64',       'LtU64($1, $2)',      'LtU64($1, $2)'), # LtU64
 
    ('',            '($1 == $2)',         '($1 == $2)'), # EqEnum
    ('',            '($1 <= $2)',         '($1 <= $2)'), # LeEnum
    ('',            '($1 < $2)',          '($1 < $2)'), # LtEnum
    ('',            '($1 == $2)',         '($1 == $2)'), # EqCh
    ('',            '($1 <= $2)',         '($1 <= $2)'), # LeCh
    ('',            '($1 < $2)',          '($1 < $2)'), # LtCh
    ('',            '($1 == $2)',         '($1 == $2)'), # EqB
    ('',            '($1 <= $2)',         '($1 <= $2)'), # LeB
    ('',            '($1 < $2)',          '($1 < $2)'), # LtB
    ('',            '($1 == $2)',         '($1 == $2)'), # EqRef
    ('',            '($1 == $2)',         '($1 == $2)'), # EqProc
    ('',            '($1 == $2)',         '($1 == $2)'), # EqPtr
    ('',            '($1 <= $2)',         '($1 <= $2)'), # LePtr
    ('',            '($1 < $2)',          '($1 < $2)'), # LtPtr
    ('',            '($1 == $2)',         '($1 == $2)'), # EqCString
    ('',            '($1 != $2)',         '($1 != $2)'), # Xor
    ('NegInt',      'NegInt($1)',         '-($1)'), # UnaryMinusI
    ('NegInt64',    'NegInt64($1)',       '-($1)'), # UnaryMinusI64
    ('AbsInt',      'AbsInt($1)',         'Math.abs($1)'), # AbsI
    ('AbsInt64',    'AbsInt64($1)',       'AbsInt64($1)'), # AbsI64
    ('',            '!($1)',              '!($1)'), # Not
    ('',            '+($1)',              '+($1)'), # UnaryPlusI
    ('',            '~($1)',              '~($1)'), # BitnotI
    ('',            '+($1)',              '+($1)'), # UnaryPlusI64
    ('',            '~($1)',              '~($1)'), # BitnotI64
    ('',            '+($1)',              '+($1)'),  # UnaryPlusF64
    ('',            '-($1)',              '-($1)'), # UnaryMinusF64
    ('',            'Math.abs($1)',       'Math.abs($1)'), # AbsF64
    ('',            'Ze($1)',             'Ze($1)'), # Ze
    ('',            'Ze64($1)',           'Ze64($1)'), # Ze64
    ('',            'ToU8($1)',           'ToU8($1)'), # ToU8
    ('',            'ToU16($1)',          'ToU16($1)'), # ToU16
    ('',            'ToU32($1)',          'ToU32($1)'), # ToU32

    ('',            '$1',                 '$1'), # ToFloat
    ('',            '$1',                 '$1'), # ToBiggestFloat
    ('',            'Math.floor($1)',     'Math.floor($1)'), # ToInt
    ('',            'Math.floor($1)',     'Math.floor($1)') # ToBiggestInt
]

names = [
# binary arithmetic with and without overflow checking:
'AddI',
'SubI',
'MulI',
'DivI',
'ModI',
'AddI64',
'SubI64',
'MulI64',
'DivI64',
'ModI64',

# other binary arithmetic operators:
'ShrI',
'ShlI',
'BitandI',
'BitorI',
'BitxorI',
'MinI',
'MaxI',
'ShrI64',
'ShlI64',
'BitandI64',
'BitorI64',
'BitxorI64',
'MinI64',
'MaxI64',
'AddF64',
'SubF64',
'MulF64',
'DivF64',
'MinF64',
'MaxF64',
'AddU',
'SubU',
'MulU',
'DivU',
'ModU',
'AddU64',
'SubU64',
'MulU64',
'DivU64',
'ModU64',

# comparison operators:
'EqI',
'LeI',
'LtI',
'EqI64',
'LeI64',
'LtI64',
'EqF64',
'LeF64',
'LtF64',
'LeU',
'LtU',
'LeU64',
'LtU64',
'EqEnum',
'LeEnum',
'LtEnum',
'EqCh',
'LeCh',
'LtCh',
'EqB',
'LeB',
'LtB',
'EqRef',
'EqProc',
'EqUntracedRef',
'LePtr',
'LtPtr',
'EqCString',
'Xor',

# unary arithmetic with and without overflow checking:
'UnaryMinusI',
'UnaryMinusI64',
'AbsI',
'AbsI64',

# other unary operations:
'Not',
'UnaryPlusI',
'BitnotI',
'UnaryPlusI64',
'BitnotI64',
'UnaryPlusF64',
'UnaryMinusF64',
'AbsF64',
'Ze',
'Ze64',
'ToU8',
'ToU16',
'ToU32',
'ToFloat',
'ToBiggestFloat',
'ToInt',
'ToBiggestInt',
]

import re, os, sys, string

i = 0

def getMagic(s):
  reWord = re.compile(r"(\w+)")
  m = reWord.match(s)
  if m and '.' not in s: return m.group(1)
  else: return ""
  
def quote(s): return "'" + s + "'"
  
for (x, y, z) in data: 
  print "(%-5s %-5s %-20s %s), // %s" % \
    (quote(getMagic(y))+',', quote(getMagic(z))+',', quote(y)+',', quote(z), names[i])
  i += 1
