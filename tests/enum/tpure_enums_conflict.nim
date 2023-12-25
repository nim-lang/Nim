discard """
  disabled: true # pure enums behave like overloadable enums now which give a different error message
  errormsg: "ambiguous identifier: 'amb'"
  line: 19
"""

# bug #8066

when true:
  type
    MyEnum {.pure.} = enum
      valueA, valueB, valueC, valueD, amb

    OtherEnum {.pure.} = enum
      valueX, valueY, valueZ, amb


  echo valueA # MyEnum.valueA
  echo MyEnum.amb # OK.
  echo amb    # Error: Unclear whether it's MyEnum.amb or OtherEnum.amb
