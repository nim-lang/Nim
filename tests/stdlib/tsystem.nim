discard """
  targets: "c cpp js"
"""

# TODO: in future work move existing `system` tests here, where they belong

template main =

  block: # system.delete
    block:
      var s = @[1]
      s.delete(0)

    block:
      var s = @["foo", "bar"]
      s.delete(1)
      doAssert @["foo"] == s
  
    block:
      var s = newSeq[string]()
      doAssertRaises(IndexDefect):
        s.delete(0)

    block:
      doAssert not compiles(@["foo"].delete(-1))

    block: # bug #6710
      var s = @["foo"]
      s.delete(0)
      doAssert s == @[]
  
    block: # bug #16544: deleting out of bounds index should raise
      var s = @["foo"]
      doAssertRaises(IndexDefect):
        s.delete(1)
  
static: main()
main()
