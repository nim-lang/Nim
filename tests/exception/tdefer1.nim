discard """
  output: '''hi
hi
1
hi
2
B
A'''
"""

# bug #1742

template test(): untyped =
    let a = 0
    defer: echo "hi"
    a

let i = test()

import strutils
let x = try: parseInt("133a")
        except: -1
        finally: echo "hi"


template atFuncEnd =
  defer:
    echo "A"
  defer:
    echo "B"

template testB(): untyped =
    let a = 0
    defer: echo "hi" # Delete this line to make it work
    a

proc main =
  atFuncEnd()
  echo 1
  let i = testB()
  echo 2

main()
