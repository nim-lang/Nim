discard """
  output: '''hi
hi'''
"""

# bug #1742

template test(): expr =
    let a = 0
    defer: echo "hi"
    a

let i = test()

import strutils
let x = try: parseInt("133a")
        except: -1
        finally: echo "hi"
