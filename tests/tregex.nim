# Test the new regular expression module
# which is based on the PCRE library

import
  regexprs, io

if "Username" =~ "[A-Za-z]+":
  echo("Yes!")
else:
  echo("Bug!")

#OUT Yes!
