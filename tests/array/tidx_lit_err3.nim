discard """
  errormsg: "size of array exceeds range of index type 'range 9223372036854775806..9223372036854775807(int)' by 1 elements"
  line: 5
"""
echo [high(int)-1: 1, 2, 3]
