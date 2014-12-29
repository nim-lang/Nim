discard """
  line: "10"
  errormsg: "'name' cannot be assigned to"
"""

echo("What's your name? ")
let name = readLine(stdin)
while name == "":
  echo("Please tell me your name: ")
  name = readLine(stdin)

