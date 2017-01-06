# Code in this module is based on:
# http://xorshift.di.unimi.it/xorshift64star.c
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


This is a good generator if you're short on memory, but otherwise we
rather suggest to use a xorshift128+ (for maximum speed) or
xorshift1024* (for speed and very long period) generator.

"""


type Xorshift64StarState* = object
  x*: uint64 # The state must be seeded with a nonzero value.

proc next*(s: var Xorshift64StarState): uint64 =
  s.x = s.x xor (s.x shr 12) # a
  s.x = s.x xor (s.x shl 25) # b
  s.x = s.x xor (s.x shr 27) # c
  return s.x * 2685821657736338717u64
