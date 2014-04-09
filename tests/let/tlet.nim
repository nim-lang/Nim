discard """
  line: "10"
  errormsg: "'name' cannot be assigned to"
"""

Echo("What's your name? ")
let name = readLine(stdin)
while name == "":
  Echo("Please tell me your name: ")
  name = readLine(stdin)

