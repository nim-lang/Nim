discard """
  output: '''
127.0.0.1
::1
(kind: true, a: [1, 2, 3])
'''
"""

# a constant object variant whose inactive branch holds an array (confutils)

import std/net

func localhost(): IpAddress =
  (static parseIpAddress("127.0.0.1"))
echo localhost()
const v6 = parseIpAddress("::1")
echo v6

type
  Inner = object
    case k: bool
    of true: x: array[8, int]
    of false: y: array[2, string]
  Outer = object
    case kind: bool
    of true: a: array[3, int]
    of false: inner: Inner

const o = Outer(kind: true, a: [1, 2, 3])
echo o
