discard """

"""

# bug #14368
# proc fun(data: string) = # different error: Error: attempt to access a nil address kind: rkInt
proc fun(data: openArray[char]) =
  doAssert data[0] == 'a' # ok
  let s = data[0].unsafeAddr # bug here
  doAssert s[] == 'a'

proc main()=
  # var s = ['a', 'b'] # works
  # var s = @['a', 'b'] # works
  var s = "ab" # will bug
  fun(s)

main() # works
static: main()

