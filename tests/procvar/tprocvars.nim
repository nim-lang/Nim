proc doSomething(v: int, x: proc(v:int):int): int = return x(v)
proc doSomething(v: int, x: proc(v:int)) = x(v)


echo doSomething(10, proc(v: int): int = return v div 2)

