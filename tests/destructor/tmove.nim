discard """
  targets: "c cpp"
"""

block:
  var called = 0

  proc bar(a: var int): var int =
    inc called
    result = a

  proc foo =
    var a = 2
    var s = move bar(a)
    doAssert called == 1
    doAssert s == 2

  foo()
