discard """
  output: '''
0
0
'''
"""

# bug #25407
template test(): typedesc =
  when true:
    int
  else:
    bool

const c = default(test())
echo c
let d = default(test())
echo d
