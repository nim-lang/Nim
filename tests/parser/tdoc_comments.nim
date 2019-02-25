
# bug #1799

proc MyProc2*() =
  ## Comment below procedure
  discard


template MyTemplate2*() = discard
  ## Comment below template


const
  MyConst1* = 1 ## Comment behind constant
  MyConst2* = 2
    ## Comment below constant


var
  MyVar1* = 1 ## Comment behind variable
  MyVar2* = 2
    ## Comment below variable


type
  MyObject1* = object
    ## Comment below declaration
    field1*: int ## Comment behind field
    field2*: int ## Comment behind field
    field3*: int
      ## Comment below field
    field4*: int
      ## Comment below field

  MyObject2* = object ## Comment behind declaration
    field1*: int


type
  MyTuple1* = tuple
    ## Comment below declaration
    tfield1: int ## Comment behind field
    tfield2: int ## Comment behind field
    tfield3: int
      ## Comment below tuple field3
    tfield4: int
      ## Comment below tuple field4

  MyTuple2* = tuple ## Comment behind declaration
    tfield1_2: int


type
  MyEnum1* = enum
    ## Comment below declaration
    value1, ## Comment behind value
    value2,
      ## Comment below value with comma
    value3
      ## Comment below value without comma

  MyEnum2* = enum ## Comment behind declaration
    value4

  MyEnum3* = enum
    value5  ## only document the enum value
