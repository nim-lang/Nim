discard """
    action: run
"""

# #7884

type Obj = object
    ö: int

let o = Obj(ö: 1)
doAssert o.ö == 1
