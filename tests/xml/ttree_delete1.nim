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
let initialDocBase = """
<xml>
  <head>
    <div>Some text</div>
    <div>Some more text </div>
  </head>
  <tag>
    <div>MORE TEXT </div>
    <div>MORE TEXT Some more text</div>
  </tag>
  <tag>
    <div>MORE TEXT </div>
    <div>MORE TEXT Some more text</div>
  </tag>
  <body>
    <div>Some text in body</div>
    <div>Some more text in body </div>
  </body>
</xml>
"""
var initialDocBaseTree = parseXml(initialDocBase)

proc test_delete() =
  var testDoc = initialDocBaseTree
  
  testDoc.delete(1)
  testDoc.delete(1)
  echo $testDoc

test_delete()
