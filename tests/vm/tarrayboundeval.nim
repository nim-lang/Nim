discard """
  output: '''7
8 8'''
"""

#bug 1063

const
  KeyMax = 227
  myconst = int((KeyMax + 31) / 32)

type
  FU = array[int((KeyMax + 31) / 32), cuint]

echo FU.high

type 
  PKeyboard* = ptr object
  TKeyboardState* = object
    display*: pointer
    internal: array[int((KeyMax + 31)/32), cuint]
    
echo myconst, " ", int((KeyMax + 31) / 32)
