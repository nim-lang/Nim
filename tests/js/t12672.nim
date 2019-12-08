discard """
output: '''
@[[2, 2, 3]]
'''
"""

proc foo =
  var x = @[[1,2,3]]
  for row in x.mitems:
    let i = 1
    inc row[i-1]
  echo x

foo()
