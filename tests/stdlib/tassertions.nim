discard """
targets: "c cpp js"
"""

template main =
  doAssertRaises(ValueError): raise newException(ValueError, "foo")
  doAssertRaises(ValueError, block: raise newException(ValueError, "foo"))
static: main()
main()

when defined(cpp) or defined(js):
  when defined(cpp):
    {.emit:"""
    #include <stdexcept>
    void fn(){throw std::runtime_error("asdf");}""".}
    proc fn(){.importcpp.}
  else:
    {.emit:"""
    function fn(){ throw 42;} """.}
    proc fn(){.importc.}

  var witness = false
  try:
    doAssertRaises(ValueError): fn()
  except AssertionDefect:
    witness = true
  doAssert witness
  doAssertRaises: fn()
  doAssertRaises(block: fn())
