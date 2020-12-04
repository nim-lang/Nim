discard """
  action: "reject"
  nimout: '''
t15667.nim(18, 5) Error: invalid indentation, maybe you forgot a '=' at t15667.nim(14, 12) ?
'''
"""



# line 10
block:
  proc asdfasdfsd() {. exportc, 
      inline
         .}     # foo
    #[
    bar
    ]#
    discard
