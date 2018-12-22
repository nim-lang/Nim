discard """
  errormsg: "'name' cannot be assigned to"
  line: "10"
"""

echo("What's your name? ")
let name = readLine(stdin)
while name == "":
  echo("Please tell me your name: ")
  name = readLine(stdin)
