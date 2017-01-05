discard """
  file: "txmltree.nim"
  output: '''true
true
true
true
true
'''
"""

import xmltree, strtabs

var x = <>a(href="nim.de", newText("www.nim-test.de"))

echo($x == "<a href=\"nim.de\">www.nim-test.de</a>")

echo(newText("foo").innerText == "foo")
echo(newEntity("bar").innerText == "bar")
echo(newComment("baz").innerText == "")

let y = newXmlTree("x", [
  newText("foo"),
  newXmlTree("y", [
    newText("bar")
  ])
])
echo(y.innerText == "foobar")
