discard """
  targets: "c cpp js"
"""

const characters = "abcdefghijklmnopqrstuvwxyz"
const numbers = "1234567890"

proc test_string_slice() =
  # test "slice of length == len(characters)":
  # replace characters completely by numbers
  var s: string
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

  when nimvm:
    discard
  else:
    # bug #6223
    doAssertRaises(IndexDefect):
      discard s[0..999]


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


#--------------------------
# bug #7816
import sugar
import sequtils

proc tester[T](x: T) =
  let test = toSeq(0..4).map(i => newSeq[int]())
  doAssert $test == "@[@[], @[], @[], @[], @[]]"



# #14497 
func reverse*(a: string): string =
  result = a
  for i in 0 ..< a.len div 2:
    swap(result[i], result[^(i + 1)])


proc main() =
  # xxx put all tests here to test in VM and RT
  test_string_slice()
  test_string_cmp()

  tester(1)

  block: # reverse
    doAssert reverse("hello") == "olleh"

  block: # len, high
    var a = "ab\0cd"
    var b = a.cstring
    doAssert a.len == 5
    block: # bug #16405
      when defined(js):
        when nimvm: doAssert b.len == 2
        else: doAssert b.len == 5
      else: doAssert b.len == 2

    doAssert a.high == a.len - 1
    doAssert b.high == b.len - 1

    doAssert "".len == 0
    doAssert "".high == -1
    doAssert "".cstring.len == 0
    doAssert "".cstring.high == -1

    var c: cstring = nil
    template impl() =
      doAssert c.len == 0
      doAssert c.high == -1
    when defined js:
      when nimvm: impl()
      else:
        # xxx pending bug #16674
        discard
    else: impl()

static: main()
main()
