# https://github.com/nim-lang/RFCs/issues/380

from mobjhash import Obj, RefObj, GenericObj1, GenericObj2, GenericObj3, GenericObj4
import tables

block:
  var t: Table[Obj, int]
  t[Obj(x: 3, y: 4, z: "debug")] = 34
  doAssert t[Obj(x: 3, y: 4, z: "ignored")] == 34
  doAssert Obj(x: 4, y: 3, z: "debug") notin t

block:
  var t: Table[RefObj, int]
  t[RefObj(x: 3, y: 4, z: "debug")] = 34
  doAssert t[RefObj(x: 3, y: 4, z: "ignored")] == 34
  doAssert RefObj(x: 4, y: 3, z: "debug") notin t

block:
  var t: Table[GenericObj1[float], int]
  t[GenericObj1[float](x: 3, y: 4, z: "debug")] = 34
  doAssert t[GenericObj1[float](x: 3, y: 4, z: "ignored")] == 34
  doAssert GenericObj1[float](x: 4, y: 3, z: "debug") notin t

block:
  var t: Table[GenericObj1[int], int]
  t[GenericObj1[int](x: 3, y: 4, z: "debug")] = 34
  doAssert t[GenericObj1[int](x: 3, y: 4, z: "ignored")] == 34
  doAssert GenericObj1[int](x: 4, y: 3, z: "debug") notin t

block:
  var t: Table[GenericObj2[float], int]
  t[GenericObj2[float](x: 3, y: 4, z: "debug")] = 34
  doAssert t[GenericObj2[float](x: 3, y: 4, z: "ignored")] == 34
  doAssert GenericObj2[float](x: 4, y: 3, z: "debug") notin t

block:
  var t: Table[GenericObj3[float], int]
  t[GenericObj3[float](x: 3, y: 4, z: "debug")] = 34
  doAssert t[GenericObj3[float](x: 3, y: 4, z: "ignored")] == 34
  doAssert GenericObj3[float](x: 4, y: 3, z: "debug") notin t

block:
  var t: Table[GenericObj4[float], int]
  t[GenericObj4[float](x: 3, y: 4, z: "debug")] = 34
  doAssert t[GenericObj4[float](x: 3, y: 4, z: "ignored")] == 34
  doAssert GenericObj4[float](x: 4, y: 3, z: "debug") notin t
