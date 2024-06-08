discard """
targets: "cpp"
errormsg: "constructor in an imported type needs importcpp pragma"
line: 14
"""
{.emit: """/*TYPESECTION*/
struct CppStruct {
  CppStruct();
};
""".}

type CppStruct {.importcpp.} = object

proc makeCppStruct(): CppStruct {.constructor.} = 
  discard