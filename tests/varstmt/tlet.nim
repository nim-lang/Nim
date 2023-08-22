discard """
  output: '''Very funny, your name is name.
nameabc'''
"""

proc main =
  let name = "name"
  if name == "":
    echo("Poor soul, you lost your name?")
  elif name == "name":
    echo("Very funny, your name is name.")
  else:
    echo("Hi, ", name, "!")

  let (x, y) = ("abc", name)
  echo y, x

main()

