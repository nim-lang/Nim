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
## surrounded by square brackets as the key name
##
## You may also return a Nim table that contains the string
## "LLDBDynamicObject" (case insensitive). This allows for dynamic
## fields to be created at runtime instead of at compile time if you
## return a Nim object as mentioned above. See the proc
## `lldbDebugSyntheticDynamicFields` below for an example

import intsets
import tables

type
  CustomType* = object of RootObj # RootObj is not necessary, but can be used
    myField*: int

  DynamicFields* = object
    customField*: string

  CustomSyntheticReturn* = object
    differentField*: float

  LLDBDynamicObject = object
    fields: TableRef[string, int]

  LLDBDynamicObjectDynamicFields = object
    fields: TableRef[string, string]

proc lldbDebugSummaryCustomType*(ty: CustomType): string {.exportc.} =
  ## Will display "CustomType(myField: <int_val>)" as a summary
  result = "CustomType" & $ty

proc lldbDebugSyntheticCustomType*(ty: CustomType): CustomSyntheticReturn {.exportc.} =
  ## Will display differentField: <float_val> as a child of CustomType instead of
  ## myField: <int_val>
  result = CustomSyntheticReturn(differentField: ty.myField.float)

proc lldbDebugSyntheticDynamicFields*(ty: DynamicFields): LLDBDynamicObjectDynamicFields {.exportc.} =
  ## Returning an object that contains "LLDBDynamicObject" in the type name will expect an
  ## object with one property that is a Nim Table/TableRef. If the key is a string,
  ## it will appear in the debugger like an object field name. The value will be whatever you
  ## set it to here as well.
  let fields = {"customFieldName": ty.customField & " MORE TEXT"}.newTable()
  return LLDBDynamicObjectDynamicFields(fields: fields)

proc lldbDebugSummaryIntSet*(intset: IntSet): string {.exportc.} =
  ## This will print the object in the LLDB summary just as Nim prints it
  result = $intset

proc lldbDebugSyntheticIntSet*(intset: IntSet): seq[int] {.exportc.} =
  ## This will create a synthetic object to make it so that IntSet
  ## will appear as a Nim object in the LLDB debugger window
  ##
  ## returning a seq here will display children like:
  ## [0]: <child_value>
  ##
  result = newSeqOfCap[int](intset.len)
  for val in intset:
    result.add(val)
