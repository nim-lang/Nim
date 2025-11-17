discard """
  cmd: "nim check --hints:off $file"
  action: reject
  nimout: '''
tproc_method_warning.nim(16, 8) Warning: 'process' is defined as both a method (dynamic dispatch) and a proc (static dispatch) at tproc_method_warning.nim(13, 6); this can be confusing. Consider using different names or only one dispatch mechanism. [User]
'''
"""

# Test warning for mixing proc and method with same name

type MyObj = ref object of RootObj

proc process(obj: MyObj) =
  echo "proc version"

method process(obj: MyObj) {.base.} =
  echo "method version"
