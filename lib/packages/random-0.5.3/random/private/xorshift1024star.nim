# Code in this module is based on:
# http://xorshift.di.unimi.it/xorshift1024star.c
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


This is a fast, top-quality generator. If 1024 bits of state are too
much, try a xorshift128+ or a xorshift64* generator.

The state must be seeded so that it is not everywhere zero. If you have
a 64-bit seed,  we suggest to seed a xorshift64* generator and use its
output to fill s.

"""


type Xorshift1024StarState* = object
  s*: array[16, uint64]
  p*: int

proc next*(s: var Xorshift1024StarState): uint64 =
  var s0 = s.s[s.p]
  s.p = (s.p + 1) and 15
  var s1 = s.s[s.p]
  s1 = s1 xor (s1 shl 31) # a
  s1 = s1 xor (s1 shr 11) # b
  s0 = s0 xor (s0 shr 30) # c
  s.s[s.p] = s0 xor s1
  return s.s[s.p] * 1181783497276652981u64
