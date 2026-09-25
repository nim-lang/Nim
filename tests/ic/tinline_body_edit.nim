discard """
  description: '''IC: editing the body of an inline proc / inline iterator regenerates its users'''
"""

#? metamorphic

# A body edit changes no importer's interface, so no user is re-semmed. The
# backend inlines these bodies into other modules anyway (an inline proc into
# every using TU, an inline iterator into the using module's lowered NIF), so
# the users' `lower`/`cg` rules have to depend on the bodies they read.

#!FILE lib.nim
proc twice*(x: int): int {.inline.} = x * 2

iterator upto*(n: int): int =
  for i in 0 ..< n: yield i

#!FILE mid.nim
import lib

proc useIt*(): int =
  result = twice(5)
  for i in upto(3): result += i

#!FILE main.nim
import mid, lib
echo useIt(), " ", twice(1)
#!STEP expect: 13 2

#!FILE lib.nim
proc twice*(x: int): int {.inline.} = x * 3

iterator upto*(n: int): int =
  for i in 0 ..< n: yield i
#!STEP expect: 18 3

#!FILE lib.nim
proc twice*(x: int): int {.inline.} = x * 3

iterator upto*(n: int): int =
  for i in 0 ..< n: yield i * 10
#!STEP expect: 45 3
