discard """
  output: '''123
2 9
2 9
'''
"""

type MyArray = array[1, int]

proc changeArray(a: var MyArray) =
    a = [123]

var a : MyArray
changeArray(a)
echo a[0]

# bug #4703
# Test 1
block:
    let ary1 = [1, 2, 3]
    var ary2 = ary1

    ary2[1] = 9

    echo ary1[1], " ", ary2[1]

# Test 2
block:
    type TestObj = ref object of RootObj
        ary2: array[3, int]

    let ary1 = [1, 2, 3]
    var obj = TestObj(ary2:ary1)

    obj.ary2[1] = 9

    echo ary1[1], " ", obj.ary2[1]
