discard """
  file: "tmultim4.nim"
  output: "hello"
"""
type
  Test = object of RootObj

method doMethod(a: ref RootObj) {.base, raises: [IoError].} =
  quit "override"

method doMethod(a: ref Test) =
  echo "hello"
  if a == nil:
    raise newException(IoError, "arg")

proc doProc(a: ref Test) =
  echo "hello"

proc newTest(): ref Test =
  new(result)

var s:ref Test = newTest()


#doesn't work
for z in 1..4:
  s.doMethod()
  break

#works
#for z in 1..4:
#  s.doProc()
#  break

#works
#while true:
#  s.doMethod()
#  break

#works
#while true:
#  s.doProc()
#  break




