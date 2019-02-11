import json

const jj = """
{
 "name" : "Peter",
 "age" : 35
}
"""

var jData {.compileTime.} = staticParseJson(jj)
#const jdata = staticParseJson(jj) # <- does *not* work!

static:
  echo jData
  doAssert jData["name"].getStr == "Peter"
  doAssert jData["age"].getInt == 35
