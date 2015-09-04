discard """
  output: '''a23: 2x3
a32: 3x2
transpose A
t32: 3x2
transpose B
x23: 2x3 (2x3)
x32: 3x2 (3x2)'''
"""

# bug #2125
# Suppose we have the following type for a rectangular array:

type
  RectArray*[R, C: static[int], T] = distinct array[R * C, T]

var a23: RectArray[2, 3, int]
var a32: RectArray[3, 2, int]

echo "a23: ", a23.R, "x", a23.C
echo "a32: ", a32.R, "x", a32.C

# Output:
# a23: 2x3
# a32: 3x2

# Looking good. Let's add a proc:
proc transpose*[R, C, T](m: RectArray[R, C, T]): RectArray[C, R, T] =
  echo "transpose A"

var t32 = a23.transpose

echo "t32: ", t32.R, "x", t32.C

# Output:
# t32: 3x2


# Everything is still OK. Now let's use the rectangular array inside another
# generic type:
type
  Matrix*[R, C: static[int], T] = object
    theArray*: RectArray[R, C, T]

#var m23: Matrix[2, 3, int]
#var m32: Matrix[3, 2, int]

#echo "m23: ", m23.R, "x", m23.C, " (", m23.theArray.R, "x", m23.theArray.C, ")"
#echo "m32: ", m32.R, "x", m32.C, " (", m32.theArray.R, "x", m32.theArray.C, ")"

# Output:
# m23: 2x3 (2x3)
# m32: 3x2 (3x2)


# Everything is still as expected. Now let's add the following proc:
proc transpose*[R, C, T](m: Matrix[R, C, T]): Matrix[C, R, T] =
  echo "transpose B"

var x23: Matrix[2, 3, int]
var x32 = x23.transpose

echo "x23: ", x23.R, "x", x23.C, " (", x23.theArray.R, "x", x23.theArray.C, ")"
echo "x32: ", x32.R, "x", x32.C, " (", x32.theArray.R, "x", x32.theArray.C, ")"

# Output:
# x23: 2x3 (2x3)
# x32: 3x2 (3x2)  <--- this is incorrect. R and C do not match!
