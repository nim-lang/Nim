# Test the new regular expression module
# which is based on the PCRE library

import
  re

if "keyA = valueA" =~ re"\s*(\w+)\s*\=\s*(\w+)":
  write(stdout, "key: ", matches[0])
elif "# comment!" =~ re.re"\s*(\#.*)": 
  # test re.re"" syntax
  echo("comment: ", matches[0])
else: 
  echo("Bug!")

if "Username".match(re"[A-Za-z]+"):
  echo("Yes!")
else:
  echo("Bug!")

#OUT key: keyAYes!
