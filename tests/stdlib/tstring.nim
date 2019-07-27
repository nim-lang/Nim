discard """
  output: "OK"
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
  doAssertRaises(IndexError):
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

proc test_string_insert() =
  var s: string

  s = numbers
  s.insert("ab", 0)
  doAssert s == "ab1234567890"

  s = numbers
  s.insert("ab", 1)
  doAssert s == "1ab234567890"

  s = numbers
  s.insert("ab", 10)
  doAssert s == "1234567890ab"

  s = numbers
  s.insert('a', 0)
  doAssert s == "a1234567890"

  s = numbers
  s.insert('a', 5)
  doAssert s == "12345a67890"

  s = numbers
  s.insert('a', 10)
  doAssert s == "1234567890a"

  s = numbers
  doAssertRaises(IndexError):
    s.insert("ab", 11)

  s = numbers
  doAssertRaises(IndexError):
    s.insert('a', 11)

test_string_slice()
test_string_cmp()
test_string_insert()
