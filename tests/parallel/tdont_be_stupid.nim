
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

sleepsort([50,3,40,25])
