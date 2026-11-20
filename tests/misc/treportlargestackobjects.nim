discard """
  action: compile
  matrix: "--reportLargeStackObjects:4096"
  nimout: '''
treportlargestackobjects.nim(19, 7) Warning: local variable 'big' of type 'Big' occupies 8192 bytes of stack space [LargeStackObject]
'''
"""

# `--reportLargeStackObjects:N` reports C locals and temporaries of N bytes
# or more; small ones and ones on the heap are not reported.

type
  Big = object
    data: array[8192, byte]
  Small = object
    data: array[16, byte]

proc main() =
  var big: Big
  var small: Small
  let heap = new Big
  big.data[0] = 1
  small.data[0] = 2
  heap.data[0] = big.data[0] + small.data[0]
  echo heap.data[0]

main()
