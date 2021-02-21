import xmltree


block:
  var
    x: XmlNode

  x = <>a(href = "http://nim-lang.org", newText("Nim rules."))
  doAssert $x == """<a href="http://nim-lang.org">Nim rules.</a>"""

  x = <>outer(<>inner())
  doAssert $x == """<outer>
  <inner />
</outer>"""

  x = <>outer(<>middle(<>inner1(), <>inner2(), <>inner3(), <>inner4()))
  doAssert $x == """<outer>
  <middle>
    <inner1 />
    <inner2 />
    <inner3 />
    <inner4 />
  </middle>
</outer>"""

  x = <>l0(<>l1(<>l2(<>l3(<>l4()))))
  doAssert $x == """<l0>
  <l1>
    <l2>
      <l3>
        <l4 />
      </l3>
    </l2>
  </l1>
</l0>"""

  x = <>l0(<>l1p1(), <>l1p2(), <>l1p3())
  doAssert $x == """<l0>
  <l1p1 />
  <l1p2 />
  <l1p3 />
</l0>"""

  x = <>l0(<>l1(<>l2p1(), <>l2p2()))
  doAssert $x == """<l0>
  <l1>
    <l2p1 />
    <l2p2 />
  </l1>
</l0>"""

  x = <>l0(<>l1(<>l2_1(), <>l2_2(<>l3_1(), <>l3_2(), <>l3_3(<>l4_1(), <>l4_2(), <>l4_3())), <>l2_3(), <>l2_4()))
  doAssert $x == """<l0>
  <l1>
    <l2_1 />
    <l2_2>
      <l3_1 />
      <l3_2 />
      <l3_3>
        <l4_1 />
        <l4_2 />
        <l4_3 />
      </l3_3>
    </l2_2>
    <l2_3 />
    <l2_4 />
  </l1>
</l0>"""

  let
    innermost = newElement("innermost")
    middle = newXmlTree("middle", [innermost])
  innermost.add newText("innermost text")
  x = newXmlTree("outer", [middle])
  doAssert $x == """<outer>
  <middle>
    <innermost>innermost text</innermost>
  </middle>
</outer>"""

  x = newElement("myTag")
  x.add newText("my text")
  x.add newElement("sonTag")
  x.add newEntity("my entity")
  doAssert $x == "<myTag>my text<sonTag />&my entity;</myTag>"
