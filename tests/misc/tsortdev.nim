discard """
  output: "done tsortdev"
"""

import algorithm, strutils

proc cmpPlatforms(a, b: string): int =
  if a == b: return 0
  var dashes = a.split('-')
  var dashes2 = b.split('-')
  if dashes[0] == dashes2[0]:
    if dashes[1] == dashes2[1]: return system.cmp(a,b)
    case dashes[1]
    of "x86":
      return 1
    of "x86_64":
      if dashes2[1] == "x86": return -1
      else: return 1
    of "ppc64":
      if dashes2[1] == "x86" or dashes2[1] == "x86_64": return -1
      else: return 1
    else:
      return system.cmp(dashes[1], dashes2[1])
  else:
    case dashes[0]
    of "linux":
      return 1
    of "windows":
      if dashes2[0] == "linux": return -1
      else: return 1
    of "macosx":
      if dashes2[0] == "linux" or dashes2[0] == "windows": return -1
      else: return 1
    else:
      if dashes2[0] == "linux" or dashes2[0] == "windows" or
         dashes2[0] == "macosx": return -1
      else:
        return system.cmp(a, b)

proc sorted[T](a: openArray[T]): bool =
  result = true
  for i in 0 ..< a.high:
    if cmpPlatforms(a[i], a[i+1]) > 0:
      echo "Out of order: ", a[i], " ", a[i+1]
      result = false

proc main() =
  var testData = @["netbsd-x86_64", "windows-x86", "linux-x86_64", "linux-x86",
    "linux-ppc64", "macosx-x86-1058", "macosx-x86-1068"]

  sort(testData, cmpPlatforms)

  doAssert sorted(testData)

for i in 0..1_000:
  main()

echo "done tsortdev"
