discard """
  cmd: "nim cpp --gc:arc --threads:on $file"
  output: '''ok1
ok2
destroyed
destroyed
destroyed
'''
"""
import threadpool, os

type
  MyObj = object
    p: int
  MyObjRef = ref MyObj

proc `=destroy`(x: var MyObj) =
  if x.p != 0:
    echo "destroyed"

proc thread1(): string =
  os.sleep(1000)
  return "ok1"

proc thread2(): ref string =
  os.sleep(1000)
  new(result)
  result[] = "ok2"

proc thread3(): ref MyObj =
  os.sleep(1000)
  new(result)
  result[].p = 2

var fv1 = spawn thread1()
var fv2 = spawn thread2()
var fv3 = spawn thread3()
sync()
echo ^fv1
echo (^fv2)[]


proc thread4(x: MyObjRef): MyObjRef {.nosinks.} =
  os.sleep(1000)
  result = x

proc thread5(x: sink MyObjRef): MyObjRef =
  os.sleep(1000)
  result = x

proc ref_forwarding_test =
  var x = new(MyObj)
  x[].p = 2
  var y = spawn thread4(x)

proc ref_sink_forwarding_test =
  var x = new(MyObj)
  x[].p = 2
  var y = spawn thread5(x)

ref_forwarding_test()
ref_sink_forwarding_test()
sync()
