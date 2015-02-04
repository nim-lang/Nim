
# bug #2039

type
    RegionTy = object
    ThingyPtr = RegionTy ptr Thingy
    Thingy = object
        next: ThingyPtr
        name: string

proc iname(t: ThingyPtr) =
    var x = t

    while not x.isNil:
        echo x.name
        x = x.next

proc go() =
    var athing : ThingyPtr

    iname(athing)

go()
