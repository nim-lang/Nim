proc doSomething(v: Int, x: proc(v:Int):Int): Int = return x(v)
proc doSomething(v: Int, x: proc(v:Int)) = x(v)


echo doSomething(10, proc(v: Int): Int = return v div 2)

