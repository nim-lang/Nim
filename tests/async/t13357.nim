discard """
  matrix: "--mm:orc; --mm:refc"
  output: '''
{"id":"9292929","name":null}
{"id":"9292929"}
'''
"""

# bug #13357: `nil` as an argument of an async proc with a `NilType` parameter
import asyncdispatch
import json
type
    NilType = type(nil)
    Unspecified = ref object
var
    unspecified: Unspecified = Unspecified()
proc `%`(opt: NilType): typeof json.newJNull() =
    return json.newJNull()
proc modifyChannel*(
        channelID: string,
        name: string | NilType | Unspecified = unspecified,
    ): Future[json.JsonNode] {.async.} =
    var node: json.JsonNode = %*{"id": channelID}
    if name != unspecified:
        node.add("name", %name)
    return node
echo waitFor modifyChannel("9292929", name=nil)
echo waitFor modifyChannel("9292929")
