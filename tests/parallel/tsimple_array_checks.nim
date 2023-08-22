discard """
sortoutput: true
output: '''
0
1
2
3
4
5
6
7
8
9
Hello 1
Hello 2
Hello 3
Hello 4
Hello 5
Hello 6
'''
"""

# bug #2287

import threadPool

# If `nums` is an array instead of seq,
# NONE of the iteration ways below work (including high / len-1)
let nums = @[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

proc log(n:int) =
  echo n

proc main =
  parallel:
    for n in nums: # Error: cannot prove: i <= len(nums) + -1
      spawn log(n)
    #for i in 0 ..< nums.len: # Error: cannot prove: i <= len(nums) + -1
    #for i in 0 .. nums.len-1: # WORKS!
    #for i in 0 ..< nums.len: # WORKS!
    #  spawn log(nums[i])

# Array needs explicit size to work, probably related to issue #2287
#const a: array[0..5, int] = [1,2,3,4,5,6]

#const a = [1,2,3,4,5,6] # Doesn't work
const a = @[1,2,3,4,5,6] # Doesn't work
proc f(n: int) = echo "Hello ", n

proc maino =
  parallel:
    # while loop doesn't work:
    var i = 0
    while i < a.high:
      #for i in countup(0, a.high-1, 2):
      spawn f(a[i])
      spawn f(a[i+1])
      i += 2

maino() # Doesn't work outside a proc

when true:
  main()

block two:
  proc f(a: openArray[int]) =
    discard

  proc main() =
    var a: array[0..9, int] = [0,1,2,3,4,5,6,7,8,9]
    parallel:
      spawn f(a[0..2])


  main()