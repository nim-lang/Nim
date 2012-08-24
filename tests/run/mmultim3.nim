type
    TObj* = object {.inheritable.}

var myObj* : ref TObj

method test123(a : ref TObj) =
    echo("Hi base!")

proc testMyObj*() =
    test123(myObj)


