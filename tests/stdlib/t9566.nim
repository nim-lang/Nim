discard """
  output: "as expected"
"""

# bug #9566: `Option` of a distinct ref type
import std/[json, options, assertions]
type TestType = distinct JsonNode

var somelongname: Option[JsonNode]
var anotherlongname: Option[TestType]

doAssert somelongname.isNone
if anotherlongname.isNone:
  echo "as expected"
