discard """
  output: '''1
1
1
1
999
999
999
2'''
"""

# test if we can pass explicit generic arguments to generic templates
# based on bug report #3496

proc     tproc[T](t: T = 999) = echo t
template ttmpl[T](t: T = 999) = echo t

tproc(1)
tproc[int](1)
ttmpl(1)
ttmpl[int](1) #<- crash case #1

tproc[int]()
let _ = tproc[int]
ttmpl[int]()  #<- crash case #2
ttmpl[int]    #<- crash case #3

# but still allow normal use of [] on non-generic templates

template tarr: untyped = [1, 2, 3, 4]
echo tarr[1]
