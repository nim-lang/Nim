discard """
  output: "@[]"
"""
import htmlparser
import xmltree
from streams import newStringStream

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

echo errors # Errors: </thead> expected,...

var len = tree.findAll("tr").len # len = 6

var rows: seq[XmlNode] = @[]
for n in tree.findAll("table"):
  n.findAll("tr", rows)  # len = 2
  break

assert tree.findAll("tr").len == rows.len
