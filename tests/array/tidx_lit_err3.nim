discard """
  errormsg: "size of array exceeds range of index type 'range 2147483646..2147483647(int32)' by 1 elements"
  line: 5
"""
echo [high(int32)-1: 1, 2, 3]
