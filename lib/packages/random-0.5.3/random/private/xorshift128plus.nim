# Code in this module is based on:
# http://xorshift.di.unimi.it/xorshift128plus.c
#
# It was ported to Nim in 2015 by Oleh Prypin <blaxpirit@gmail.com>
#
# The following are the verbatim comments from the original code:

discard """

Written in 2014 by Sebastiano Vigna (vigna@acm.org)

To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty.

See <http://creativecommons.org/publicdomain/zero/1.0/>.


This is the fastest generator passing BigCrush without systematic
errors, but due to the relatively short period it is acceptable only
for applications with a very mild amount of parallelism; otherwise, use
a xorshift1024* generator.

The state must be seeded so that it is not everywhere zero. If you have
a 64-bit seed, we suggest to pass it twice through MurmurHash3's
avalanching function.

"""


type Xorshift128PlusState* = object
  s*: array[2, uint64]

proc next*(s: var Xorshift128PlusState): uint64 =
  var s1 = s.s[0]
  let s0 = s.s[1]
  s.s[0] = s0
  s1 = s1 xor (s1 shl 23u64) # a
  s.s[1] = s1 xor s0 xor (s1 shr 17) xor (s0 shr 26) # b, c
  return s.s[1] + s0
