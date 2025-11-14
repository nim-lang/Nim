# Test case: Typo in identifier name
# WHY IT MATTERS: Developers often make small typos (lenght vs length)
# and waste time trying to figure out what went wrong.

proc calculateArea(width, height: int): int =
  # Common typo: "lenght" instead of "length"
  echo "Width: ", width
  # This will trigger "did you mean" suggestion
  if width.lenght > 10:  # Typo: should be "len"
    return width * height
  return 0

# Another common case: misspelling imported symbols
import std/strutils

let text = "Hello World"
# Typo: "toLowercase" instead of "toLowerAscii"
echo text.toLowercase()  # Should suggest: toLowerAscii, to LowerCase, etc.
