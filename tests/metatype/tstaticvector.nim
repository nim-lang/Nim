
type
  RectArray*[R, C: static[int], T] = distinct array[R * C, T]
   
  StaticMatrix*[R, C: static[int], T] = object
    elements*: RectArray[R, C, T]
   
  StaticVector*[N: static[int], T] = StaticMatrix[N, 1, T]
 
proc foo*[N, T](a: StaticVector[N, T]): T = 0.T
proc foobar*[N, T](a, b: StaticVector[N, T]): T = 0.T
 
 
var a: StaticVector[3, int]
 
echo foo(a) # OK
echo foobar(a, a) # <--- hangs compiler 
