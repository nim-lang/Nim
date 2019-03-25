discard """
  targets: "cpp"
  action: "compile"
"""

type
  String* {.importcpp: "std::string", header: "string".} = object

proc initString*(): String
    {.importcpp: "std::string()", header: "string".}

proc append*(this: var String, str: String): var String
    {.importcpp: "append", header: "string", discardable.}

var
  s1 = initString()
  s2 = initString()

s1.append s2
