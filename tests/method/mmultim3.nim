type
    TObj* {.inheritable.} = object

var myObj* : ref TObj

method test123(a : ref TObj) {.base.} =
    echo("Hi base!")

proc testMyObj*() =
    test123(myObj)


