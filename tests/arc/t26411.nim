proc checkEmptyAppend(empty: string; operation: static int) =
  block:
    # Make reused storage expose a missing terminator.
    var tmp = newString(4)
    for i in 0 ..< tmp.len:
      tmp[i] = 'Z'

  var s = "abc"
  when operation == 0:
    s.add ""
  elif operation == 1:
    s.add empty
  else:
    s &= empty

  doAssert s == "abc"
  # Check the allocated terminator byte before scanning the C string.
  doAssert cstring(s)[s.len] == '\0'
  doAssert cstring(s).len == s.len
  doAssert $cstring(s) == "abc"

checkEmptyAppend("", 0)
checkEmptyAppend(newString(0), 1)
checkEmptyAppend(newString(0), 2)
