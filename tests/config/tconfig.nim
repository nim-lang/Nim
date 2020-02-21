discard """
  output: '''false'''
  joinable: "false"
"""

# We used to evaluate  tconfig.nim.cfg before config/config.nims
# and so this was true, now it is false:

echo defined(nimIgnoreThisSwitch)
