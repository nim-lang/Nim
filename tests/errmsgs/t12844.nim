discard """
cmd: "nim check $file"
errormsg: "cannot assign template 'z' to 'y'. Did you mean to call the template with '()'?"
nimout: '''
t12844.nim(11, 11) Error: cannot assign template 'z' to 'x'. Did you mean to call the template with '()'?
t12844.nim(12, 9) Error: cannot assign template 'z' to 'y'. Did you mean to call the template with '()'?'''
"""

template z*(args: varargs[string, `$`]) =
  discard
const x = z
var y = z

