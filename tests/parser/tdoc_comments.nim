
# bug #1799

proc MyProc1*() = ## Comment behind procedure
  discard

proc MyProc2*() =
  ## Comment below procedure
  discard


template MyTemplate1*() = discard ## Comment behind template

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
    field1: int ## Comment behind field
    field2: int ## Comment behind field
    field3: int
      ## Comment below field
    field4: int
      ## Comment below field

  MyTuple2* = tuple ## Comment behind declaration
    field1: int


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

# bug #18847
proc close*() =   ## asdfasdfsdfa
  discard         ## adsfasdfads
