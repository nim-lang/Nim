discard """
  output: '''
declare v_26003
2
'''
"""

var v {.codegenDecl: "console.log('declare $2'); var $2".} = 2
echo v
