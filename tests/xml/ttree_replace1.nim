discard """
  output: '''
<xml>
  <head>
    <div>Some text</div>
    <div>Some more text </div>
  </head>
  <body>
    <div>Some text in body</div>
    <div>Some more text in body </div>
  </body>
</xml>
'''
"""

# Test xmltree add/insert/delete/replace operations
import xmlparser
import xmltree
var baseDocHead = """
  <head>
    <div>Some text</div>
    <div>Some more text </div>
  </head>
"""
var baseDocHeadTree = parseXml(baseDocHead)
var baseDocBody = """
<body>
  <div>Some text in body</div>
  <div>Some more text in body </div>
</body>
"""
var baseDocBodyTree = parseXml(baseDocBody)
let initialDocBase = """
<xml>
  <head>
    <div>Some text before replace </div>
    <div>Some more text before replace </div>
  </head>
  <body>
    <div>Some text in body before replace </div>
    <div>Some more text in body before replace </div>
  </body>
</xml>
"""
var initialDocBaseTree = parseXml(initialDocBase)

proc test_replace() =
  var testDoc = initialDocBaseTree
  
  testDoc.replace(0..1, @[baseDocHeadTree, baseDocBodyTree])
  echo $testDoc

test_replace()
