from mimportsb {.all.} import fnb1, hfnb3

proc fn1*(): int = 1
proc fn2*(): int = 2
proc hfn3(): int = 3
proc hfn4(): int = 4
proc hfn5(): int = 5

export mimportsb.fnb2, hfnb3
