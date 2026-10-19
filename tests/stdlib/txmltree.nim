discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/[xmltree, assertions, xmlparser]


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

block: # bug #21290
  let x = newXmlTree("foo",[
    newXmlTree("bar",[
      newText("Hola"),
      newXmlTree("qux",[
        newXmlTree("plugh",[])
      ])
    ])
  ])

  let s = $x
  doAssert $parseXml(s) == s
  doAssert s == """<foo>
  <bar>Hola<qux>    <plugh />  </qux></bar>
</foo>"""

block: #21541
  let root = <>root()
  root.add <>child(newText("hello"))
  root.add <>more(newVerbatimText("hola"))
  let s = $root
  doAssert s == """<root>
  <child>hello</child>
  <more>hola</more>
</root>"""

  let temp = newVerbatimText("Hello!")
  doAssert temp.text == "Hello!"
  temp.text = "Hola!"
  doAssert temp.text == "Hola!"

block: #26039
  let tree = <>rss(
    "xmlns:atom" = "http://www.w3.org/2005/Atom",
    <>"atom:link"(
      `data-dummy` = "test",
    ),
  )
  doAssert $tree == """<rss xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:link data-dummy="test" />
</rss>"""

block: # bug #24062
  let value = "line1\nline2\r\n\tend"
  let tree = <>a(b = value)
  doAssert $tree == """<a b="line1&#10;line2&#13;&#10;&#9;end" />"""
  doAssert parseXml($tree).attr("b") == value
  # text keeps its line breaks
  doAssert $(<>a(newText("x\ny"))) == "<a>x\ny</a>"

block: # bug #25462
  let x = parseXml("""<foo>
  <bar>x</bar>
  <!-- c -->
  <baz>y</baz>
</foo>""")
  doAssert x.tag == "foo"
  doAssert x.len == 3
  doAssert x[0].kind == xnElement
  doAssert x[0].tag == "bar"
  doAssert x[0].len == 1
  doAssert x[0][0].kind == xnText
  doAssert x[0][0].text == "x"
  doAssert x[1].kind == xnComment
  doAssert x[1].text == " c "
  doAssert x[2].kind == xnElement
  doAssert x[2].tag == "baz"
  doAssert x[2].len == 1
  doAssert x[2][0].kind == xnText
  doAssert x[2][0].text == "y"

  # no regression regarding bug #1518: whitespace within character data
  # interrupted by a comment is kept
  let y = parseXml("<a>x<!-- c --> y</a>")
  doAssert y.tag == "a"
  doAssert y.len == 4
  doAssert y[0].kind == xnText
  doAssert y[0].text == "x"
  doAssert y[1].kind == xnComment
  doAssert y[1].text == " c "
  doAssert y[2].kind == xnText
  doAssert y[2].text == " "
  doAssert y[3].kind == xnText
  doAssert y[3].text == "y"
