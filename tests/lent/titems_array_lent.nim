discard """
  targets: "c cpp js"
"""

template sameAddress(a, b): bool =
  when defined(js):
    a == b
  else:
    a.unsafeAddr == b.unsafeAddr

proc main() =
  block:
    let a = [10, 11, 12]
    for ai in items(a):
      doAssert sameAddress(ai, a[0])
      break

  block:
    let a = [[1, 2], [1, 2], [1, 2]]
    for ai in items(a):
      doAssert sameAddress(ai[0], a[0][0])
      break

  block:
    let s = @[(1, 2), (3, 4), (5, 6)]
    doAssert (3, 4) in s

main()

static:
  main()

block: # issue #25849
  static:
    const key = "NIM_TESTS_TOSENV_KEY"
    for val in ["val", "", "\xc3\x86"]:
      let s = @[(key, "val"), (key, ""), (key, "\xc3\x86")]
      doAssert (key, val) in s