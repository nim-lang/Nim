# `$` tests are scattered but should be here since we have `lib/system/dollars.nim`

template main() =
  var a = "abc"
  var b = a[0].unsafeAddr
  doAssert type(b) is ptr char
  when nimvm: discard
  else:
    doAssert cast[cstring](b) == "abc"
  doAssert not compiles $b

static: main()
main()
