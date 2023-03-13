## This is a demo file containing an example of how to
## create custom LLDB summaries and objects with synthetic
## children. These are implemented in Nim and called from the Python
## nimlldb.py module.
##
## For summaries, prefix your proc names with "lldbDebugSummary", use
## the `{.exportc.}` pragma, and return a string. Also, any `$` proc
## that is available will be used for a given type.
##
## For creating a synthetic object (LLDB will display the children), use
## the prefix "lldbDebugSynthetic", use the `{.exportc.}` pragma, and
## return any Nim object, array, or sequence. Returning a Nim object
## will display the fields and values of the object as children.
## Returning an array or sequence will display children with the index
## and value.

import intsets

type
  CustomType* = object of RootObj # RootObj is not necessary, but can be used
    myField*: int

  CustomSyntheticReturn* = object
    differentField*: float


proc lldbDebugSummaryCustomType*(ty: CustomType): string {.exportc.} =
  ## Will display "CustomType(myField: 0)" as a summary
  result = "CustomType" & $ty

proc lldbDebugSyntheticCustomType*(ty: CustomType): CustomSyntheticReturn {.exportc.} =
  ## Will display the fields of CustomSyntheticReturn as children of
  ## CustomType
  result = CustomSyntheticReturn(differentField: ty.myField.float)

proc lldbDebugSummaryIntSet*(intset: IntSet): string {.exportc.} =
  ## This will print the object in the LLDB summary just as Nim prints it
  result = $intset

proc lldbDebugSyntheticIntSet*(intset: IntSet): seq[int] {.exportc.} =
  ## This will create a synthetic object to make it so that IntSet
  ## will appear as a Nim object in the LLDB debugger window
  ##
  ## returning a seq here will display children like:
  ##
  result = newSeqOfCap[int](intset.len)
  for val in intset:
    result.add(val)
