discard """
joinable: false
cmd: "nim check $file"
errormsg: "type bound operation `=deepcopy` can be defined only in the same module with its type (MyTestObject)"
nimout: '''
terror_module.nim(14, 1) Error: type bound operation `=destroy` can be defined only in the same module with its type (MyTestObject)
terror_module.nim(16, 1) Error: type bound operation `=sink` can be defined only in the same module with its type (MyTestObject)
terror_module.nim(18, 1) Error: type bound operation `=` can be defined only in the same module with its type (MyTestObject)
terror_module.nim(20, 1) Error: type bound operation `=deepcopy` can be defined only in the same module with its type (MyTestObject)
'''
"""
import helper

proc `=destroy`[T](x: var MyTestObject[T]) = discard

proc `=sink`[T](x: var MyTestObject[T], y:MyTestObject[T]) = discard

proc `=`[T](x: var MyTestObject[T], y: MyTestObject[T]) = discard

proc `=deepcopy`[T](x: ptr MyTestObject[T]): ptr MyTestObject[T] = discard
