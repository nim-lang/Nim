discard """
  output: '''
caught! 2'''
  cmd: "nim c --gc:arc --exceptions:goto $file"
"""

proc silly(x: int): seq[int] =
  for i in 1..x: result.add i

proc take1(x: seq[int]): int = x[0]

proc parseJunk(s: string; res: var int) =
  for c in s:
    case c
    of 'A'..'Z':
      discard "wtf"
      res = take1 silly(26)
    of 'a'..'z':
      res = take1 silly(8)
    of '0'..'9':
      res = take1 silly(10)
    else:
      raise newException(ValueError, "invalid char: " & c)

var res: int
parseJunk("abcdefASDSFAF0090", res)
echo res

when false:
  proc canRaise(p: int) =
    if p < 3004:
      raise newException(ValueError, "")

  proc noraise {.importc, nodecl.}

  proc main(p: proc(); q: proc() {.raises: [].} ) =
    # {.raises: [].} =
    echo "foo bar"
    noraise()
    canRaise(4)
    if p != nil: p()
    if q != nil: q()

  proc other(p: int): int =
    let x = 3 + p
    result = x - 8

  main(nil, nil)
  echo other(89)
