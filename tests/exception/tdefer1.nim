discard """
  targets: "c cpp js"
  output: '''
hi1
1
hi2
2
B
A
ok4
ok6
ok8
ok7
ok5
'''
"""

# see also: tests/exception/tdefer2.nim

# bug #1742

import strutils
let x = try: parseInt("133a")
        except: -1
        finally: echo "hi1"


template atFuncEnd =
  defer:
    echo "A"
  defer:
    echo "B"

template testB(): untyped =
  let a = 0
  defer: echo "hi2"
  a

proc main =
  atFuncEnd()
  echo 1
  let i = testB()
  echo 2

main()

template main2 =
  # defer at top-level scope
  echo "ok4"
  defer: echo "ok5"
  echo "ok6"
  defer: echo "ok7"
  echo "ok8"

static: main2()
main2()
