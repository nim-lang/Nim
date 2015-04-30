discard """
  output: '''(one: 1, two: 2, three: 3)
1
2
3
(one: 4, two: 5, three: 6)
4
(one: 7, two: 8, three: 9)
7
8
9'''
"""

# bug #2134
type
    TestType = object
        one: int
        two: int
        three: int

var
    ab = TestType(one:1, two:2, three:3)
    ac = TestType(one:4, two:5, three:6)
    ad = TestType(one:7, two:8, three:9)
    tstSeq = [ab, ac, ad]

for tstElement in mitems(tstSeq):
    echo tstElement
    for tstField in fields(tstElement):
        #for tstField in [1,2,4,6]:
        echo tstField
        if tstField == 4:
            break
