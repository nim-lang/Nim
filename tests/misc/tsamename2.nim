proc fooBar*()=discard
proc fooBar2*()=discard
proc callFun*[Fun](processPattern: Fun) =
  processPattern()
