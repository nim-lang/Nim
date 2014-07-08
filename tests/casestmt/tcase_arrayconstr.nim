discard """
  output: '''Not found!
Found!'''
"""

const
  md_extension = [".md", ".markdown"]

proc test(ext: string) =
  case ext
  of ".txt", md_extension:
    echo "Found!"
  else:
    echo "Not found!"

test(".something")
# ensure it's not evaluated at compile-time:
var foo = ".markdown"
test(foo)
