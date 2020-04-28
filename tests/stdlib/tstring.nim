discard """
  output: '''OK
@[@[], @[], @[], @[], @[]]
'''
"""
const characters = "abcdefghijklmnopqrstuvwxyz"
const numbers = "1234567890"

var s: string

proc test_string_slice() =
  # test "slice of length == len(characters)":
  # replace characters completely by numbers
  s = characters
  s[0..^1] = numbers
  doAssert s == numbers

  # test "slice of length > len(numbers)":
  # replace characters by slice of same length
  s = characters
  s[1..16] = numbers
  doAssert s == "a1234567890rstuvwxyz"

  # test "slice of length == len(numbers)":
  # replace characters by slice of same length
  s = characters
  s[1..10] = numbers
  doAssert s == "a1234567890lmnopqrstuvwxyz"

  # test "slice of length < len(numbers)":
  # replace slice of length. and insert remaining chars
  s = characters
  s[1..4] = numbers
  doAssert s == "a1234567890fghijklmnopqrstuvwxyz"

  # test "slice of length == 1":
  # replace first character. and insert remaining 9 chars
  s = characters
  s[1..1] = numbers
  doAssert s == "a1234567890cdefghijklmnopqrstuvwxyz"

  # test "slice of length == 0":
  # insert chars at slice start index
  s = characters
  s[2..1] = numbers
  doAssert s == "ab1234567890cdefghijklmnopqrstuvwxyz"

  # test "slice of negative length":
  # same as slice of zero length
  s = characters
  s[2..0] = numbers
  doAssert s == "ab1234567890cdefghijklmnopqrstuvwxyz"

  # bug #6223
  doAssertRaises(IndexDefect):
    discard s[0..999]

  echo("OK")

proc test_string_cmp() =
  let world = "hello\0world"
  let earth = "hello\0earth"
  let short = "hello\0"
  let hello = "hello"
  let goodbye = "goodbye"

  doAssert world == world
  doAssert world != earth
  doAssert world != short
  doAssert world != hello
  doAssert world != goodbye

  doAssert cmp(world, world) == 0
  doAssert cmp(world, earth) > 0
  doAssert cmp(world, short) > 0
  doAssert cmp(world, hello) > 0
  doAssert cmp(world, goodbye) > 0

test_string_slice()
test_string_cmp()


#--------------------------
# bug #7816
import sugar
import sequtils

proc tester[T](x: T) =
  let test = toSeq(0..4).map(i => newSeq[int]())
  echo test

tester(1)

