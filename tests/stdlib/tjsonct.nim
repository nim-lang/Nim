import json

const jj = """
{
  "name" : "Peter",
  "age" : 35,
  "data" : [1, 2, 3, 4],
  "nested" : { "low" : 0,
               "high" : 1 }
}
"""

var jData {.compileTime.} = staticParseJson(jj)
#const jdata = staticParseJson(jj) # <- does *not* work!

static:
  echo jData
  doAssert jData["name"].getStr == "Peter"
  doAssert jData["age"].getInt == 35
  doAssert jData["data"] == % [1, 2, 3, 4]
  doAssert jData["nested"].kind == JObject
  doAssert jData["nested"]["low"].getInt == 0
  doAssert jData["nested"]["high"].getInt == 1
