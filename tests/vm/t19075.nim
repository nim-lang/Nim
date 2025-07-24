discard """
  timeout: 10
  joinable: false
"""

# bug #19075
const size = 50_000

const stuff = block:
    var a: array[size, int]
    a

const zeugs = block:
    var zeugs: array[size, int]
    for i in 0..<size:
        zeugs[i] = stuff[i]
    zeugs

doAssert zeugs[0] == 0