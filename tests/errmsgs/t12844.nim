discard """
cmd: "nim check $file"
errormsg: "invalid type: 'template (args: varargs[string])' for var. Did you mean to call the template with '()'?"
nimout: '''
t12844.nim(11, 7) Error: invalid type: 'template (args: varargs[string])' for const. Did you mean to call the template with '()'?
t12844.nim(12, 5) Error: invalid type: 'template (args: varargs[string])' for var. Did you mean to call the template with '()'?'''
"""

template z*(args: varargs[string, `$`]) =
  discard
const x = z
var y = z

