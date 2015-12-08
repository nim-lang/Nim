discard """
  file: "issue_416_template_shift.nim"
"""
import unicode, sequtils

proc test() =
  let input = readFile("weird.nim")
  for letter in runes(string(input)):
    echo int(letter)

when 1 > 0:
  proc failtest() =
    let
      input = readFile("weird.nim")
      letters = toSeq(runes(string(input)))
    for letter in letters:
      echo int(letter)

when isMainModule:
  test()
