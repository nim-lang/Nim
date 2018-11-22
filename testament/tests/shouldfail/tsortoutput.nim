discard """
sortoutput: true
output: '''
2
1
'''
"""

# this test should ensure that the output is actually sorted
echo "2"
echo "1"

#[
    of "file": result.file = e.value
    of "tfile": result.tfile = e.value
    of "tline": discard parseInt(e.value, result.tline)
    of "tcolumn": discard parseInt(e.value, result.tcolumn)
    of "nimout":
      result.nimout = e.value
    of "disabled":
      case e.value.normalize
      of "y", "yes", "true", "1", "on": result.err = reIgnored
      of "n", "no", "false", "0", "off": discard
      of "win", "windows":
        when defined(windows): result.err = reIgnored
      of "linux":
        when defined(linux): result.err = reIgnored
      of "bsd":
        when defined(bsd): result.err = reIgnored
      of "macosx":
        when defined(macosx): result.err = reIgnored
      of "unix":
        when defined(unix): result.err = reIgnored
      of "posix":
        when defined(posix): result.err = reIgnored
      of "travis":
        if isTravis: result.err = reIgnored
      of "appveyor":
        if isAppVeyor: result.err = reIgnored
      else:
        raise newException(ValueError, "cannot interpret as a bool: " & e.value)
    of "cmd":
      if e.value.startsWith("nim "):
        result.cmd = compilerPrefix & e.value[4..^1]
      else:
        result.cmd = e.value
    of "ccodecheck": result.ccodeCheck = e.value
    of "maxcodesize": discard parseInt(e.value, result.maxCodeSize)
    of "target", "targets":
      for v in e.value.normalize.splitWhitespace:
        case v
        of "c": result.targets.incl(targetC)
        of "cpp", "c++": result.targets.incl(targetCpp)
        of "objc": result.targets.incl(targetObjC)
        of "js": result.targets.incl(targetJS)
        else: echo ignoreMsg(p, e)
    else: echo ignoreMsg(p, e)
]#
