discard """
  targets: "c cpp js"
"""

proc main()=
  block:
    let a = -0.0
    doAssert $a == "-0.0"
    doAssert $(-0.0) == "-0.0"

  block:
    let a = 0.0
    when nimvm: discard ## TODO VM print wrong -0.0
    else:
      doAssert $a == "0.0"
    doAssert $(0.0) == "0.0"

  block:
    let b = -0
    doAssert $b == "0"
    doAssert $(-0) == "0"

  block:
    let b = 0
    doAssert $b == "0"
    doAssert $(0) == "0"


static: main()
main()
