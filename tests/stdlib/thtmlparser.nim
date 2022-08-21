discard """
  targets: "c js"
  output: '''
true
https://example.com/test?format=jpg&name=orig##
https://example.com/test?format=jpg&name=orig##text
https://example.com/test?format=jpg##text
'''
"""
import htmlparser
import xmltree
import strutils
from streams import newStringStream


block t2813:
  const
    html = """
    <html>
      <head>
        <title>Test</title>
      </head>
      <body>
        <table>
          <thead>
            <tr><td>A</td></tr>
            <tr><td>B</td></tr>
          </thead>
          <tbody>
            <tr><td></td>A<td></td></tr>
            <tr><td></td>B<td></td></tr>
            <tr><td></td>C<td></td></tr>
          </tbody>
          <tfoot>
            <tr><td>A</td></tr>
          </tfoot>
        </table>
      </body>
    </html>
    """
  var errors: seq[string] = @[]
  let tree = parseHtml(newStringStream(html), "test.html", errors)
  doAssert errors.len == 0 # Errors: </thead> expected,...

  var len = tree.findAll("tr").len # len = 6
  var rows: seq[XmlNode] = @[]
  for n in tree.findAll("table"):
    n.findAll("tr", rows)  # len = 2
    break
  doAssert tree.findAll("tr").len == rows.len


block t2814:
  ## builds the two cases below and test that
  ## ``//[dd,li]`` has "<p>that</p>" as children
  ##
  ##  <dl>
  ##    <dt>this</dt>
  ##    <dd>
  ##      <p>that</p>
  ##    </dd>
  ##  </dl>

  ##
  ## <ul>
  ##   <li>
  ##     <p>that</p>
  ##   </li>
  ## </ul>
  for ltype in [["dl","dd"], ["ul","li"]]:
    let desc_item = if ltype[0]=="dl": "<dt>this</dt>" else: ""
    let item = "$1<$2><p>that</p></$2>" % [desc_item, ltype[1]]
    let list = """ <$1>
     $2
  </$1> """ % [ltype[0], item]

    var errors : seq[string] = @[]
    let parseH = parseHtml(newStringStream(list),"statichtml", errors =errors)

    if $parseH.findAll(ltype[1])[0].child("p") != "<p>that</p>":
      echo "case " & ltype[0] & " failed !"
      quit(2)
  echo "true"

block t6154:
  let foo = """
  <!DOCTYPE html>
  <html>
      <head>
        <title> foobar </title>
      </head>
      <body>
        <p class=foo id=bar></p>
        <p something=&#9;foo&#9;bar&#178;></p>
        <p something=  &#9;foo&#9;bar&#178; foo  =bloo></p>
        <p class="foo2" id="bar2"></p>
        <p wrong= ></p>
        <p data-foo data-bar="correct!" enabled  ></p>
        <p quux whatever></p>
      </body>
  </html>
  """

  var errors: seq[string] = @[]
  let html = parseHtml(newStringStream(foo), "statichtml", errors=errors)
  doAssert "statichtml(11, 18) Error: attribute value expected" in errors
  let ps = html.findAll("p")
  doAssert ps.len == 7

  doAssert ps[0].attrsLen == 2
  doAssert ps[0].attr("class") == "foo"
  doAssert ps[0].attr("id") == "bar"
  doAssert ps[0].len == 0

  doAssert ps[1].attrsLen == 1
  doAssert ps[1].attr("something") == "\tfoo\tbar²"
  doAssert ps[1].len == 0

  doAssert ps[2].attrsLen == 2
  doAssert ps[2].attr("something") == "\tfoo\tbar²"
  doAssert ps[2].attr("foo") == "bloo"
  doAssert ps[2].len == 0

  doAssert ps[3].attrsLen == 2
  doAssert ps[3].attr("class") == "foo2"
  doAssert ps[3].attr("id") == "bar2"
  doAssert ps[3].len == 0

  doAssert ps[4].attrsLen == 1
  doAssert ps[4].attr("wrong") == ""

  doAssert ps[5].attrsLen == 3
  doAssert ps[5].attr("data-foo") == ""
  doAssert ps[5].attr("data-bar") == "correct!"
  doAssert ps[5].attr("enabled") == ""
  doAssert ps[5].len == 0

  doAssert ps[6].attrsLen == 2
  doAssert ps[6].attr("quux") == ""
  doAssert ps[6].attr("whatever") == ""
  doAssert ps[6].len == 0

# bug #11713, #1034
var content = """
# with &
<img src="https://example.com/test?format=jpg&name=orig" alt="">
<img src="https://example.com/test?format=jpg&name=orig" alt="text">

# without &
<img src="https://example.com/test?format=jpg" alt="text">
"""

var
  stream = newStringStream(content)
  body = parseHtml(stream)

for y in body.findAll("img"):
  echo y.attr("src"), "##", y.attr("alt")
