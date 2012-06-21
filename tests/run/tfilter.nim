discard """
  output: "02468101214161820"
"""

proc filter[T](list: seq[T], f: proc (item: T): bool {.closure.}): seq[T] =
  result = @[]
  for i in items(list):
    if f(i):
      result.add(i)

let nums = @[0, 1, 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]

when true:
  let nums2 = filter(nums,
               (proc (item: int): bool =
                 result = (item mod 2) == 0)
               )

proc outer =
  # lets use a proper closure this time:
  var modulo = 2
  let nums2 = filter(nums,
               (proc (item: int): bool = result = (item mod modulo) == 0)
               )

  for n in nums2: stdout.write(n)

outer()
