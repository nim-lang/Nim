discard """
  errormsg: "has to be used (or discarded)"
  line: 27
"""

# Page 35.

proc implicit: string =
  "I will be returned"

proc discarded: string =
  discard "I will not be returned"

proc explicit: string =
  return "I will be returned"

proc resultVar: string =
  result = "I will be returned"

proc resultVar2: string =
  result = ""
  result.add("I will be ")
  result.add("returned")

proc resultVar3: string =
  result = "I am the result"
  "I will cause an error"

doAssert implicit() == "I will be returned"
doAssert discarded() == nil
doAssert explicit() == "I will be returned"
doAssert resultVar() == "I will be returned"
doAssert resultVar2() == "I will be returned"
