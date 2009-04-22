# Test the new regular expression module
# which is based on the PCRE library

import
  regexprs

if "keyA = valueA" =~ r"\s*(\w+)\s*\=\s*(\w+)":
  write(stdout, "key: ", matches[1])
elif "# comment!" =~ r"\s*(\#.*)":
  echo("comment: ", matches[1])
else: 
  echo("Bug!")

if "Username".match("[A-Za-z]+"):
  echo("Yes!")
else:
  echo("Bug!")

#OUT key: keyAYes!
