discard """
  output: '''123
2 9
2 9
1 124
true false
100 300 100
1
1
'''
"""

type MyArray = array[1, int]

proc changeArray(a: var MyArray) =
    a = [123]

var a: MyArray
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
    var obj = TestObj(ary2: ary1)

    obj.ary2[1] = 9

    echo ary1[1], " ", obj.ary2[1]

block:
    type TestObj = object
        x, y: int

    let obj = TestObj(x: 1, y: 2)
    var s = @[obj]
    s[0].x += 123
    echo obj.x, " ", s[0].x

block:
    var nums = {1, 2, 3, 4}
    let obj = (n: nums)
    nums.incl 5
    echo (5 in nums), " ", (5 in obj.n)

block:
    let tup1 = (a: 100)
    var tup2 = (t: (t2: tup1))
    var tup3 = tup1
    tup2.t.t2.a = 300
    echo tup1.a, " ", tup2.t.t2.a, " ", tup3.a

block:
    proc foo(arr: array[2, int]) =
        var s = @arr
        s[0] = 500

    var nums = [1, 2]
    foo(nums)
    echo nums[0]

proc bug9674 =
  var b = @[1,2,3]
  var a = move(b)
  echo a[0]

bug9674()
