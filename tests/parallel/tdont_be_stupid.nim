discard """
output: '''
100
200
300
400
'''
"""

import threadpool, os

proc single(time: int) =
  sleep time
  echo time

proc sleepsort(nums: openArray[int]) =
  parallel:
    var i = 0
    while i <= len(nums) + -1:
      spawn single(nums[i])
      i += 1

sleepsort([400,100,300,200])
