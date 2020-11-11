discard """
output: '''0

0.0'''
"""

# bug #11494
import macros

macro staticForEach(arr: untyped, body: untyped): untyped =
    result = newNimNode(nnkStmtList)

    arr.expectKind(nnkBracket)
    for n in arr:
        let b = copyNimTree(body)
        result.add quote do:
            block:
                type it {.inject.} = `n`
                `b`

template forEveryMatchingEntity*() =
    staticForEach([int, string, float]):
        var a: it
        echo a

forEveryMatchingEntity()


# bug #11483
proc main =
  template first(body) =
    template second: var int =
      var o: int
      var i  = addr(o)
      i[]

    body

  first:
    second = 5
    second = 6

main()

