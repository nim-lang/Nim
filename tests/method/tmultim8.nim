
# bug #3550

type 
  BaseClass = ref object of RootObj
  Class1 = ref object of BaseClass
  Class2 = ref object of BaseClass
  
method test(obj: Class1, obj2: BaseClass) =
  discard

method test(obj: Class2, obj2: BaseClass) =
  discard
  
var obj1 = Class1()
var obj2 = Class2()

obj1.test(obj2) 
obj2.test(obj1)
